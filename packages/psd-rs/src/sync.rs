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
//! - All commands converge: a profile already in the target state
//!   (live overlay for startup/resync, torn down for unsync) is a
//!   success, not an error. systemd restarts this unit on NixOS
//!   generation switches (`ExecStop` -> `ExecStart`), so unsync followed
//!   by startup on a live session must succeed.
//! - Busy profiles: unsync persists the delta (final resync, safe
//!   while the app runs) and leaves the overlay live instead of
//!   failing -- tearing down under a writing app would corrupt state,
//!   and a failed stop job wedges the switch.
//! - Unsync teardown is rename-based: `BACK_OVFS` is a complete mirror
//!   (rsync --delete-after), so it is renamed into place as `DIR`
//!   atomically; no merge pass, no mid-merge corruption window.
//! - Unmount before unlinking `DIR`: a busy mount (EBUSY) fails
//!   cleanly with the session fully intact.
//! - fsync before the final rename, so a crash mid-unsync leaves a
//!   consistent `BACK_OVFS` for next-boot recovery.
//! - The PID file means "a session is live": removed only when no
//!   overlay remains, so the resync timer keeps covering profiles left
//!   live by unsync. It contains the actual PID, so stale detection is
//!   possible.
//!
//! ## TODO: dirty tracking
//!
//! Unsync does a full `TMP -> BACK_OVFS` rsync even if nothing changed
//! since the last resync. Tracking overlay writes would let us skip
//! that scan when clean. The `TimeoutStopSec` race that motivated this
//! is gone (unsync is one scan + atomic renames, and busy profiles
//! skip teardown entirely); dirty tracking would only save the scan.

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

/// True if the app's process is running for `user`.
fn app_running(kind: AppKind, user: &str) -> Result<bool> {
    let psname = kind.process_name();
    // pgrep -x -u <user> <name>
    let out = Command::new("pgrep")
        .args(["-x", "-u", user, psname])
        .output()
        .context("spawning pgrep")?;
    Ok(out.status.success())
}

/// Refuse to proceed if the app is running, to avoid corrupting state
/// under a writing app (we don't kill it).
pub fn ensure_app_not_running(kind: AppKind, user: &str) -> Result<()> {
    let psname = kind.process_name();
    if app_running(kind, user)? {
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
/// Non-live profiles are skipped -- one dead profile must not fail
/// the timer run for the healthy ones.
pub fn resync(state: &State, profile: &AppProfile) -> Result<()> {
    let paths = state.paths_for(profile);
    if !paths.is_live() {
        debug!(dir = %paths.dir.display(), "not live; skipping resync");
        return Ok(());
    }
    rsync_sync(
        &paths.dir,
        &paths.back_ovfs,
        /* exclude_flagged */ true,
    )?;
    info!(app = %profile.kind.as_ref(), "resync ok");
    Ok(())
}

/// Unsync: persist the delta, then tear down -- unless the app is
/// running, in which case the profile is left live (see module docs).
///
/// Non-live profiles are a no-op; teardown is rename-based:
/// `BACK_OVFS` (a complete mirror) is renamed into place as `DIR`.
pub fn unsync(state: &State, profile: &AppProfile) -> Result<()> {
    let paths = state.paths_for(profile);
    if !paths.is_live() {
        debug!(dir = %paths.dir.display(), "not live; unsync is a no-op");
        return Ok(());
    }

    // Persist the delta first: safe while the app runs (the resync
    // timer does the same thing), so the on-disk staging copy is fresh
    // no matter how the rest of this goes.
    rsync_sync(
        &paths.dir,
        &paths.back_ovfs,
        /* exclude_flagged */ true,
    )?;

    // Busy profile: keep the overlay live. Tearing down under a
    // writing app would corrupt state, and a failed stop job would
    // wedge a systemd restart (NixOS switch).
    if app_running(profile.kind, &state.user)? {
        warn!(
            app = %profile.kind.as_ref(),
            dir = %paths.dir.display(),
            "app running; delta persisted, leaving overlay live"
        );
        return Ok(());
    }

    // Unmount before unlinking the symlink: a busy mount (EBUSY) bails
    // here with the session fully intact instead of orphaning DIR.
    overlay::unmount(&paths.tmp)?;

    // Durable before the rename: a crash past this point leaves a
    // consistent BACK_OVFS for next-boot recovery.
    fsync_dir(&paths.back_ovfs)?;

    fs::remove_file(&paths.dir)
        .with_context(|| format!("unlink {}", paths.dir.display()))?;
    // Tmpfs cleanup is best-effort -- the durable state is already in
    // BACK_OVFS, and tmpfs is wiped on reboot anyway.
    let _ = fs::remove_dir_all(&paths.tmp);
    let _ = fs::remove_dir_all(&paths.upper);
    let _ = fs::remove_dir_all(&paths.work);

    // BACK_OVFS is a complete mirror of the overlay view; rename it
    // into place atomically (same parent dir) instead of merging.
    fs::rename(&paths.back_ovfs, &paths.dir).with_context(|| {
        format!(
            "rename {} -> {}",
            paths.back_ovfs.display(),
            paths.dir.display()
        )
    })?;
    // The frozen lowerdir is superseded by the renamed mirror. If
    // removal fails, the next startup rotates the stale BACKUP aside
    // -- not worth failing the unit over.
    if paths.backup.exists()
        && let Err(e) = fs::remove_dir_all(&paths.backup)
    {
        warn!(
            dir = %paths.backup.display(),
            error = %e,
            "failed to remove superseded backup"
        );
    }

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
