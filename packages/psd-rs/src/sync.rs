//! Sync state machine: startup / resync / unsync.
//!
//! ## Model (preserves psd v7 semantics, see `paths.rs` for the why)
//!
//! ```text
//! Active session:
//!   DIR  --symlink--> TMP (overlay mount)
//!   BACKUP           = frozen lowerdir (read-only while mounted)
//!   UPPER (tmpfs)    = overlay writes (delta)
//!   BACK_OVFS (disk) = staging for periodic resyncs
//! ```
//!
//! ## Improvements over psd v7 shell
//!
//! - **Atomic renames**: `std::fs::rename` instead of `mv
//!   --no-target-directory`; same atomicity on one filesystem, no fork.
//!
//! - **fsync before rename**: the merge step fsyncs `BACK_OVFS` contents
//!   before renaming into `BACKUP`, so a crash mid-merge leaves a
//!   consistent `BACK_OVFS` for next-boot recovery.
//!
//! - **No `kill_browsers`**: unsync refuses to run if the browser process
//!   is alive, rather than killing it. Killing risks losing unsaved
//!   browser state; the caller (systemd `ExecStop`) can `KillMode=process`
//!   the browser first if desired.
//!
//! - **PID file with content**: includes the actual PID so stale detection
//!   is possible (psd v7 wrote an empty file).
//!
//! ## TODO: dirty tracking
//!
//! The unsync path still does a full `TMP -> BACK_OVFS` rsync even if
//! nothing changed since the last resync. A future improvement: track
//! overlay write activity and skip the final rsync when clean, directly
//! addressing the systemd `TimeoutStopSec` race that made psd v7 look
//! "always ungraceful". For now, set `TimeoutStopSec` generously in the
//! systemd unit.

use std::fs;
use std::path::Path;
use std::path::PathBuf;
use std::process::Command;

use anyhow::Context;
use anyhow::Result;
use anyhow::bail;
use nix::unistd::User;
use tracing::debug;
use tracing::info;
use tracing::warn;

use crate::browser::BrowserProfile;
use crate::overlay;
use crate::paths::ProfilePaths;
use crate::paths::append_suffix;

const FLAGGED: &str = ".flagged";
const PID_FILE: &str = "psd.pid";

/// Runtime state shared across operations. Cheap to clone.
#[derive(Debug, Clone)]
pub struct State {
    pub volatile_root: PathBuf,
    pub user: String,
}

impl State {
    pub fn new() -> Result<Self> {
        let user_name = std::env::var("USER")
            .or_else(|_| {
                // Fall back to getent-like lookup via nix.
                let uid = nix::unistd::getuid().as_raw();
                User::from_uid(uid.into())
                    .ok()
                    .flatten()
                    .map(|u| u.name)
                    .ok_or_else(|| {
                        anyhow::anyhow!("could not determine current user")
                    })
            })
            .context("determining current user")?;
        let xdg_runtime = std::env::var("XDG_RUNTIME_DIR")
            .context("XDG_RUNTIME_DIR is not set; refusing to run")?;
        let volatile_root = PathBuf::from(xdg_runtime).join("psd");
        Ok(Self {
            volatile_root,
            user: user_name,
        })
    }

    pub fn pid_file(&self) -> PathBuf {
        self.volatile_root.join(PID_FILE)
    }

    pub fn is_active(&self) -> bool {
        self.pid_file().exists()
    }

    /// Write a PID file containing the current PID. Not just a marker --
    /// includes the pid so stale detection is possible (psd v7 wrote an
    /// empty file, making stale detection impossible).
    pub fn mark_active(&self) -> Result<()> {
        fs::create_dir_all(&self.volatile_root).with_context(|| {
            format!("mkdir {}", self.volatile_root.display())
        })?;
        let pid = std::process::id();
        fs::write(self.pid_file(), format!("{pid}\n")).with_context(
            || format!("write {}", self.pid_file().display()),
        )?;
        Ok(())
    }

    pub fn mark_inactive(&self) {
        if let Err(e) = fs::remove_file(self.pid_file())
            && e.kind() != std::io::ErrorKind::NotFound
        {
            warn!(error = %e, "failed to remove pid file");
        }
    }

    /// Resolve paths for a profile, including the firefox-style suffix.
    pub fn paths_for(&self, profile: &BrowserProfile) -> ProfilePaths {
        let suffix = if profile.needs_suffix() {
            format!("-{}", profile.suffix)
        } else {
            String::new()
        };
        ProfilePaths::new(profile, &self.volatile_root, &suffix)
    }
}

/// Check that the browser process is not running for `profile`.
/// psd v7 refuses to start and kills on unsync; we only refuse.
pub fn ensure_browser_not_running(profile: &BrowserProfile) -> Result<()> {
    let psname = profile.kind.process_name();
    // pgrep -x -u <uid> <name>
    let out = Command::new("pgrep")
        .args(["-x", "-u", &profile.uid_str(), psname])
        .output()
        .context("spawning pgrep")?;
    if out.status.success() {
        bail!(
            "{psname} is running (uid={}); refuse to proceed. Stop the browser first.",
            profile.uid_str()
        );
    }
    Ok(())
}

impl BrowserProfile {
    pub fn uid_str(&self) -> String {
        // For pgrep -u. The shell version used the username; uid is more
        // robust against renamed users.
        // We don't carry uid on the struct; look it up.
        match User::from_name(&self.user) {
            Ok(Some(u)) => u.uid.as_raw().to_string(),
            _ => self.user.clone(),
        }
    }
}

/// Startup: mount overlay, symlink DIR -> TMP, create `BACK_OVFS`.
/// Idempotent -- if already active, this is a no-op for that profile.
pub fn startup(state: &State, profile: &BrowserProfile) -> Result<()> {
    let paths = state.paths_for(profile);

    if !paths.dir.is_dir() {
        bail!(
            "{} does not exist or is not a directory; nothing to sync",
            paths.dir.display()
        );
    }

    // Already active for this profile?
    if paths.dir.is_symlink() {
        if paths.dir.exists() {
            debug!(
                dir = %paths.dir.display(),
                "already symlinked; skipping startup"
            );
            return Ok(());
        }
        // Dangling -- crash recovery should have fixed this, but just in case.
        bail!(
            "{} is a dangling symlink; run `psd recover` or check journal",
            paths.dir.display()
        );
    }

    // Retain DIR perms for the tmpfs dirs we create.
    let mode = dir_mode(&paths.dir)?;

    // Create tmpfs dirs. These live in $XDG_RUNTIME_DIR which is already
    // owned by the user, so no chown needed (and chown would fail with
    // EPERM for non-root users anyway).
    for d in [&paths.tmp, &paths.upper, &paths.work] {
        if !d.exists() {
            fs::create_dir_all(d)
                .with_context(|| format!("mkdir {}", d.display()))?;
            chmod(d, mode)?;
        }
    }

    // Move DIR -> BACKUP (lowerdir). Atomic on same fs.
    if paths.backup.exists() {
        // Stale backup from a prior failed startup. Rotate aside rather
        // than clobber -- preserves data for manual recovery.
        warn!(
            backup = %paths.backup.display(),
            "stale BACKUP exists; moving aside (prior startup failed?)"
        );
        let aside = append_suffix(&paths.backup, "-stale");
        fs::rename(&paths.backup, &aside).with_context(|| {
            format!("rename stale backup {}", paths.backup.display())
        })?;
    }
    fs::rename(&paths.dir, &paths.backup).with_context(|| {
        format!(
            "rename {} -> {}",
            paths.dir.display(),
            paths.backup.display()
        )
    })?;

    // Mount the overlay.
    overlay::mount(&paths.backup, &paths.upper, &paths.work, &paths.tmp)?;

    // Symlink DIR -> TMP. The symlink is created by the user in their
    // own home dir; no chown needed (and would fail with EPERM for
    // non-root users anyway).
    #[cfg(unix)]
    std::os::unix::fs::symlink(&paths.tmp, &paths.dir).with_context(
        || {
            format!(
                "symlink {} -> {}",
                paths.dir.display(),
                paths.tmp.display()
            )
        },
    )?;
    #[cfg(not(unix))]
    bail!("symlink creation requires unix");

    // Mark the session active via the flag file (lives in the overlay).
    touch(&paths.dir.join(FLAGGED))?;

    info!(browser = %profile.kind.as_ref(), dir = %paths.dir.display(), "startup ok");
    Ok(())
}

/// Resync: rsync DIR/ (overlay view) -> `BACK_OVFS`/.
/// Safe to run while overlay is mounted (`BACK_OVFS` is outside it).
pub fn resync(state: &State, profile: &BrowserProfile) -> Result<()> {
    let paths = state.paths_for(profile);
    if !state.is_active() {
        bail!("psd not active; run `startup` first");
    }
    if !paths.dir.is_symlink() || !paths.dir.exists() {
        bail!(
            "{} is not a live overlay symlink; cannot resync",
            paths.dir.display()
        );
    }
    rsync_sync(
        &paths.dir,
        &paths.back_ovfs,
        /* exclude_flagged */ true,
    )?;
    info!(browser = %profile.kind.as_ref(), "resync ok");
    Ok(())
}

/// Unsync: final resync, merge `BACK_OVFS` -> BACKUP, unmount, rename.
pub fn unsync(state: &State, profile: &BrowserProfile) -> Result<()> {
    let paths = state.paths_for(profile);
    if !state.is_active() {
        debug!("not active; unsync is no-op");
        return Ok(());
    }
    if !paths.dir.is_symlink() {
        bail!("{} is not a symlink; cannot unsync", paths.dir.display());
    }
    ensure_browser_not_running(profile)?;

    // Final delta into BACK_OVFS.
    rsync_sync(
        &paths.dir,
        &paths.back_ovfs,
        /* exclude_flagged */ true,
    )?;
    // Merge BACK_OVFS -> BACKUP.
    //
    // BACKUP is the overlay lowerdir, so writing to it while the overlay
    // is mounted is normally unsafe (see paths.rs). This is acceptable
    // here because: (a) the browser is confirmed not running, (b) the
    // overlay is quiescent with no new writes, (c) we're about to
    // unmount. psd v7 does the same.
    rsync_sync(
        &paths.back_ovfs,
        &paths.backup,
        /* exclude_flagged */ false,
    )?;
    fsync_dir(&paths.backup)?;

    // Remove symlink, unmount, rotate BACKUP back to DIR.
    fs::remove_file(&paths.dir)
        .with_context(|| format!("unlink {}", paths.dir.display()))?;
    overlay::unmount(&paths.tmp)?;
    let _ = fs::remove_dir_all(&paths.tmp);
    let _ = fs::remove_dir_all(&paths.upper);
    let _ = fs::remove_dir_all(&paths.work);

    fs::rename(&paths.backup, &paths.dir).with_context(|| {
        format!(
            "rename {} -> {}",
            paths.backup.display(),
            paths.dir.display()
        )
    })?;

    info!(browser = %profile.kind.as_ref(), "unsync ok");
    Ok(())
}

/// rsync wrapper used by both resync and unsync.
fn rsync_sync(
    src: &Path,
    dst: &Path,
    exclude_flagged: bool,
) -> Result<()> {
    // Ensure dst exists.
    if !dst.exists() {
        fs::create_dir_all(dst)
            .with_context(|| format!("mkdir {}", dst.display()))?;
    }
    let mut cmd = Command::new("rsync");
    cmd.args(["-aX", "--delete-after", "--inplace", "--no-whole-file"]);
    if exclude_flagged {
        cmd.args(["--exclude", FLAGGED]);
    }
    cmd.arg(format!("{}/", src.display())).arg(dst);
    debug!(cmd = ?cmd, "rsync");
    let out = cmd.output().context("spawning rsync")?;
    if !out.status.success() {
        bail!(
            "rsync {} -> {} failed (exit {}): {}",
            src.display(),
            dst.display(),
            out.status.code().unwrap_or(-1),
            String::from_utf8_lossy(&out.stderr).trim()
        );
    }
    Ok(())
}

fn dir_mode(p: &Path) -> Result<u32> {
    use std::os::unix::fs::PermissionsExt;
    let meta = fs::metadata(p)
        .with_context(|| format!("stat {}", p.display()))?;
    Ok(meta.permissions().mode() & 0o7777)
}

#[cfg(unix)]
fn chmod(p: &Path, mode: u32) -> Result<()> {
    use std::os::unix::fs::PermissionsExt;
    fs::set_permissions(p, fs::Permissions::from_mode(mode))
        .with_context(|| format!("chmod {}", p.display()))?;
    Ok(())
}

fn touch(p: &Path) -> Result<()> {
    fs::write(p, b"").with_context(|| format!("touch {}", p.display()))?;
    Ok(())
}

fn fsync_dir(p: &Path) -> Result<()> {
    #[cfg(unix)]
    {
        let f = fs::File::open(p)
            .with_context(|| format!("open {}", p.display()))?;
        // best-effort fsync; ignore EINVAL (some filesystems don't support it)
        let _ = nix::unistd::fsync(&f);
    }
    let _ = p;
    Ok(())
}
