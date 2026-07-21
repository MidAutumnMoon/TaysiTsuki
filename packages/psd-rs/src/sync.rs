//! Sync state machine: startup / resync / unsync.
//!
//! ```text
//! Active session:
//!   DIR  --symlink--> TMP (overlay mount)
//!   BACKUP           = frozen lowerdir (read-only while mounted)
//!   UPPER (tmpfs)    = overlay writes (delta)
//!   BACK_OVFS (disk) = staging for periodic resyncs
//! ```
//!
//! Design notes:
//!
//! - Atomic renames for the DIR/BACKUP swap.
//! - fsync before the final rename, so a crash mid-merge leaves a
//!   consistent `BACK_OVFS` for next-boot recovery.
//! - unsync refuses if the app is running instead of killing it, to
//!   avoid losing unsaved state.
//! - PID file contains the actual PID, so stale detection is possible.
//!
//! ## TODO: dirty tracking
//!
//! Unsync does a full `TMP -> BACK_OVFS` rsync even if nothing changed
//! since the last resync. Tracking overlay writes would let us skip it
//! when clean, avoiding the `TimeoutStopSec` race where unsync is killed
//! mid-rsync and the next boot looks ungraceful. For now,
//! `TimeoutStopSec` is set generously in the systemd unit.

use std::fs;
use std::path::Path;
use std::path::PathBuf;
use std::process::Command;

use anyhow::Context;
use anyhow::Result;
use anyhow::bail;
use tracing::debug;
use tracing::info;
use tracing::warn;

use crate::apps::AppKind;
use crate::apps::AppProfile;
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
        let user = std::env::var("USER")
            .context("USER is not set; refusing to run")?;
        let xdg_runtime = std::env::var("XDG_RUNTIME_DIR")
            .context("XDG_RUNTIME_DIR is not set; refusing to run")?;
        Ok(Self {
            volatile_root: PathBuf::from(xdg_runtime).join("psd"),
            user,
        })
    }

    pub fn pid_file(&self) -> PathBuf {
        self.volatile_root.join(PID_FILE)
    }

    pub fn is_active(&self) -> bool {
        self.pid_file().exists()
    }

    /// Write a PID file containing the current PID (not just a marker,
    /// so stale detection is possible).
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

    pub fn paths_for(&self, profile: &AppProfile) -> ProfilePaths {
        ProfilePaths::new(profile, &self.volatile_root)
    }
}

/// Refuse to proceed if the app is running, to avoid losing unsaved
/// state (we don't kill it).
pub fn ensure_app_not_running(kind: AppKind, user: &str) -> Result<()> {
    let psname = kind.process_name();
    // pgrep -x -u <user> <name>
    let out = Command::new("pgrep")
        .args(["-x", "-u", user, psname])
        .output()
        .context("spawning pgrep")?;
    if out.status.success() {
        bail!(
            "{psname} is running (user={user}); refuse to proceed. \
             Stop the app first."
        );
    }
    Ok(())
}

/// Startup: mount overlay, symlink DIR -> TMP, create `BACK_OVFS`.
/// Idempotent -- if already active, this is a no-op for that profile.
pub fn startup(state: &State, profile: &AppProfile) -> Result<()> {
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

    // Create tmpfs dirs (TMP, UPPER, WORK) with the same mode as DIR.
    for d in [&paths.tmp, &paths.upper, &paths.work] {
        if !d.exists() {
            fs::create_dir_all(d)
                .with_context(|| format!("mkdir {}", d.display()))?;
            copy_mode(&paths.dir, d)?;
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

    // Symlink DIR -> TMP so the app sees the overlay view.
    std::os::unix::fs::symlink(&paths.tmp, &paths.dir).with_context(
        || {
            format!(
                "symlink {} -> {}",
                paths.dir.display(),
                paths.tmp.display()
            )
        },
    )?;

    // .flagged lives inside the overlay (tmpfs), so its absence after a
    // reboot signals ungraceful shutdown (see `crash::recover`).
    touch(&paths.dir.join(FLAGGED))?;

    info!(app = %profile.kind.as_ref(), dir = %paths.dir.display(), "startup ok");
    Ok(())
}

/// Resync: rsync DIR/ (overlay view) -> `BACK_OVFS`/.
/// Safe to run while overlay is mounted (`BACK_OVFS` is outside it).
pub fn resync(state: &State, profile: &AppProfile) -> Result<()> {
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
    info!(app = %profile.kind.as_ref(), "resync ok");
    Ok(())
}

/// Unsync: final resync, merge `BACK_OVFS` -> BACKUP, unmount, rename.
pub fn unsync(state: &State, profile: &AppProfile) -> Result<()> {
    let paths = state.paths_for(profile);
    if !state.is_active() {
        debug!("not active; unsync is no-op");
        return Ok(());
    }
    if !paths.dir.is_symlink() {
        bail!("{} is not a symlink; cannot unsync", paths.dir.display());
    }
    ensure_app_not_running(profile.kind, &state.user)?;

    // Final delta into BACK_OVFS.
    rsync_sync(
        &paths.dir,
        &paths.back_ovfs,
        /* exclude_flagged */ true,
    )?;
    // Merge BACK_OVFS -> BACKUP. Writing to the lowerdir while the
    // overlay is mounted is normally unsafe (see paths.rs), but here the
    // app is stopped, the overlay is quiescent, and we unmount next.
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
    // Tmpfs cleanup is best-effort -- the durable state is already in
    // BACKUP, and tmpfs is wiped on reboot anyway.
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

    info!(app = %profile.kind.as_ref(), "unsync ok");
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

/// Copy permission bits from `src` to `dst`.
fn copy_mode(src: &Path, dst: &Path) -> Result<()> {
    use std::os::unix::fs::PermissionsExt;
    let mode = fs::metadata(src)
        .with_context(|| format!("stat {}", src.display()))?
        .permissions()
        .mode();
    fs::set_permissions(dst, fs::Permissions::from_mode(mode))
        .with_context(|| format!("chmod {}", dst.display()))?;
    Ok(())
}

fn touch(p: &Path) -> Result<()> {
    fs::write(p, b"").with_context(|| format!("touch {}", p.display()))?;
    Ok(())
}

fn fsync_dir(p: &Path) -> Result<()> {
    let f = fs::File::open(p)
        .with_context(|| format!("open {}", p.display()))?;
    // best-effort fsync; ignore EINVAL (some filesystems don't support it)
    let _ = f.sync_all();
    Ok(())
}
