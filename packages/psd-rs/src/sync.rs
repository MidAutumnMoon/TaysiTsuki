//! Profile mount lifecycle: startup and explicit unsync.
//!
//! Checkpoint construction and publication live in `checkpoint.rs`.
//!
//! ```text
//! Active session:
//!   DIR  --symlink--> TMP (overlay mount)
//!   BACKUP           = frozen lowerdir (read-only while mounted)
//!   UPPER (tmpfs)    = overlay writes (the delta)
//!   BACK_OVFS (disk) = last atomically committed checkpoint
//! ```
//!
//! Invariants:
//!
//! - Commands converge: a profile already in the target state is a success.
//! - Each FUSE daemon is owned by an independent transient user service.
//! - Never write a lowerdir (`BACKUP`) while its overlay is mounted.
//! - Automatic systemd stop only checkpoints. Destructive `unsync` is an
//!   explicit command and refuses when a known app process is running.
//! - Unsync promotes a committed `BACK_OVFS` to `DIR` with an atomic rename.
//! - Unmount before unlinking `DIR`, and verify the mount postcondition before
//!   advancing to the next transition.
//!
//! TODO: track dirty upperdirs so clean profiles skip checkpoint scans.

use std::env;
use std::fs;
use std::fs::remove_dir_all;
use std::io::ErrorKind;
use std::os::unix::fs::symlink;
use std::path::Path;
use std::path::PathBuf;
use std::process::Command;

use anyhow::Context as _;
use anyhow::Result;
use anyhow::bail;
use tracing::debug;
use tracing::info;
use tracing::warn;

use crate::apps::AppKind;
use crate::apps::AppProfile;
use crate::apps::ProcessMatch;
use crate::checkpoint;
use crate::exec;
use crate::overlay;
use crate::paths::ProfilePaths;
use crate::paths::SessionState;
use crate::paths::append_suffix;

/// Runtime state shared across operations. Cheap to clone.
#[derive(Debug, Clone)]
pub struct State {
    pub volatile_root: PathBuf,
    pub user: String,
}

impl State {
    pub fn new() -> Result<Self> {
        let user = env::var("USER")
            .context("USER is not set; refusing to run")?;
        let runtime_dir = PathBuf::from(
            env::var("XDG_RUNTIME_DIR")
                .context("XDG_RUNTIME_DIR is not set; refusing to run")?,
        );
        if !runtime_dir.is_absolute() {
            bail!(
                "XDG_RUNTIME_DIR must be absolute, got {}",
                runtime_dir.display()
            );
        }
        Ok(Self {
            volatile_root: runtime_dir.join("psd"),
            user,
        })
    }

    /// Serialize every mutating command for this user session.
    pub fn acquire_lock(&self) -> Result<fs::File> {
        fs::create_dir_all(&self.volatile_root).with_context(|| {
            format!("mkdir {}", self.volatile_root.display())
        })?;
        let lock_path = self.volatile_root.join(".lock");
        let lock = fs::OpenOptions::new()
            .create(true)
            .write(true)
            .truncate(false)
            .open(&lock_path)
            .with_context(|| {
                format!("open lock {}", lock_path.display())
            })?;
        lock.lock()
            .with_context(|| format!("lock {}", lock_path.display()))?;
        Ok(lock)
    }

    pub fn paths_for(&self, profile: &AppProfile) -> ProfilePaths {
        ProfilePaths::new(profile, &self.volatile_root)
    }
}

/// True if the app's process is running for `user`.
pub fn app_running(kind: AppKind, user: &str) -> Result<bool> {
    let mut command = Command::new("pgrep");
    command.arg("-u").arg(user);
    match kind.process_match() {
        ProcessMatch::Name(name) => {
            command.args(["-x", name]);
        }
        ProcessMatch::CommandLine(pattern) => {
            command.args(["-f", "-x", pattern]);
        }
    }
    let output = exec::output(&mut command)?;
    // 0 = match, 1 = no match; other codes mean pgrep itself failed
    // and must not look like "not running".
    match output.status.code() {
        Some(0) => Ok(true),
        Some(1) => Ok(false),
        code => bail!(
            "pgrep failed (exit {}): {}",
            code.unwrap_or(-1),
            String::from_utf8_lossy(&output.stderr).trim(),
        ),
    }
}

/// True only when the managed symlink and actual overlay mount are live.
pub fn overlay_live(paths: &ProfilePaths) -> Result<bool> {
    match paths.session_state()? {
        SessionState::Live => Ok(true),
        SessionState::PlainDirectory | SessionState::Missing => Ok(false),
        SessionState::StaleSymlink => {
            warn!(
                dir = %paths.dir.display(),
                tmp = %paths.tmp.display(),
                "managed symlink outlived its overlay; startup recovery required"
            );
            Ok(false)
        }
        SessionState::OrphanMount => {
            bail!(
                "{} is mounted without {}; run `psd recover` before syncing",
                paths.tmp.display(),
                paths.dir.display()
            );
        }
        SessionState::DisconnectedMount => {
            bail!(
                "overlay for {} is disconnected because its fuse-overlayfs \
                 daemon exited; run `psd startup` to reconnect it",
                paths.dir.display()
            );
        }
    }
}

/// Startup: mount the overlay and symlink DIR -> TMP.
///
/// Precondition: the caller serialized commands, skipped live profiles, and
/// ran `crash::recover`; `DIR` must be a plain directory here.
pub fn startup(state: &State, profile: &AppProfile) -> Result<()> {
    let paths = state.paths_for(profile);

    if paths.dir.is_symlink() || !paths.dir.is_dir() {
        bail!(
            "{} is not a plain directory; expected `recover` to have \
             normalized it first",
            paths.dir.display()
        );
    }
    // A checkpoint marker may remain in a plain profile only if a previous
    // promotion was interrupted after its atomic rename.
    checkpoint::remove_marker(&paths.dir)
        .context("remove checkpoint marker from plain profile")?;

    // Tmpfs dirs inherit DIR's mode.
    for directory in [&paths.tmp, &paths.upper, &paths.work] {
        if !directory.exists() {
            fs::create_dir_all(directory).with_context(|| {
                format!("mkdir {}", directory.display())
            })?;
            copy_mode(&paths.dir, directory)?;
        }
    }

    if let Some(metadata) = metadata_if_exists(&paths.backup)? {
        if !metadata.is_dir() {
            bail!(
                "{} is not a plain backup directory",
                paths.backup.display()
            );
        }
        // Stale backup from a failed startup: rotate aside, never clobber.
        let aside = next_stale_backup(&paths.backup)?;
        warn!(
            backup = %paths.backup.display(),
            aside = %aside.display(),
            "stale BACKUP exists; moving aside (prior startup failed?)"
        );
        fs::rename(&paths.backup, &aside).with_context(|| {
            format!(
                "rename stale backup {} -> {}",
                paths.backup.display(),
                aside.display()
            )
        })?;
    }
    // DIR becomes the frozen lowerdir (atomic same-dir rename).
    fs::rename(&paths.dir, &paths.backup).with_context(|| {
        format!(
            "rename {} -> {}",
            paths.dir.display(),
            paths.backup.display()
        )
    })?;

    if let Err(error) = overlay::mount(
        &paths.backup,
        &paths.upper,
        &paths.work,
        &paths.tmp,
    ) {
        return Err(rollback_failed_startup(&paths, error));
    }

    // The app sees the overlay through this symlink.
    if let Err(error) =
        symlink(&paths.tmp, &paths.dir).with_context(|| {
            format!(
                "symlink {} -> {}",
                paths.dir.display(),
                paths.tmp.display()
            )
        })
    {
        return Err(rollback_failed_startup(&paths, error));
    }

    info!(app = %profile.kind.as_ref(), dir = %paths.dir.display(), "startup ok");
    Ok(())
}

fn rollback_failed_startup(
    paths: &ProfilePaths,
    error: anyhow::Error,
) -> anyhow::Error {
    match rollback_startup(paths) {
        Ok(()) => error,
        Err(rollback_error) => error.context(format!(
            "startup rollback also failed: {rollback_error:#}"
        )),
    }
}

fn rollback_startup(paths: &ProfilePaths) -> Result<()> {
    if matches!(
        overlay::mount_state(&paths.tmp)?,
        overlay::MountState::Mounted | overlay::MountState::Disconnected
    ) {
        overlay::unmount(&paths.tmp)?;
    }

    match fs::symlink_metadata(&paths.dir) {
        Err(error) if error.kind() == ErrorKind::NotFound => {}
        Err(error) => {
            return Err(error).with_context(|| {
                format!("inspect {}", paths.dir.display())
            });
        }
        Ok(_) => {
            bail!(
                "{} appeared during startup; refusing to replace it while \
                 rolling back",
                paths.dir.display()
            );
        }
    }
    fs::rename(&paths.backup, &paths.dir).with_context(|| {
        format!(
            "restore {} -> {}",
            paths.backup.display(),
            paths.dir.display()
        )
    })?;

    for directory in [&paths.tmp, &paths.upper, &paths.work] {
        match remove_dir_all(directory) {
            Ok(()) => {}
            Err(error) if error.kind() == ErrorKind::NotFound => {}
            Err(error) => {
                return Err(error).with_context(|| {
                    format!("remove {}", directory.display())
                });
            }
        }
    }
    Ok(())
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ResyncOutcome {
    Committed,
    SourceChanged,
    Skipped,
}

/// Resync: refresh `BACK_OVFS` from the overlay view. Safe while
/// mounted -- the target sits outside the overlay. Non-live profiles
/// are skipped.
pub fn resync(
    state: &State,
    profile: &AppProfile,
) -> Result<ResyncOutcome> {
    let paths = state.paths_for(profile);
    if !overlay_live(&paths)? {
        debug!(dir = %paths.dir.display(), "not live; skipping resync");
        return Ok(ResyncOutcome::Skipped);
    }
    match checkpoint::run(&paths)? {
        checkpoint::Outcome::Committed => {
            info!(app = %profile.kind.as_ref(), "resync ok");
            Ok(ResyncOutcome::Committed)
        }
        checkpoint::Outcome::SourceChanged => {
            warn!(
                app = %profile.kind.as_ref(),
                dir = %paths.dir.display(),
                "profile changed during resync; previous checkpoint remains \
                 committed"
            );
            Ok(ResyncOutcome::SourceChanged)
        }
    }
}

/// Per-profile result of [`unsync`].
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum UnsyncOutcome {
    /// Torn down; the profile is back on disk as a plain directory.
    TornDown,
    /// Not live; nothing to do.
    Skipped,
}

/// Unsync: explicitly checkpoint and tear down one profile. The caller must
/// close the application first. Non-live profiles are a no-op.
pub fn unsync(
    state: &State,
    profile: &AppProfile,
) -> Result<UnsyncOutcome> {
    let paths = state.paths_for(profile);
    if !overlay_live(&paths)? {
        debug!(dir = %paths.dir.display(), "not live; unsync is a no-op");
        return Ok(UnsyncOutcome::Skipped);
    }

    // Migration: old versions left a `.flagged` marker in the overlay;
    // don't let it reach the real profile.
    let _ = fs::remove_file(paths.dir.join(".flagged"));

    // Persist first -- safe under a running app -- so the staging copy
    // is fresh no matter what follows.
    let mut sync_outcome = checkpoint::run(&paths)?;
    if sync_outcome == checkpoint::Outcome::SourceChanged {
        if app_running(profile.kind, &state.user)? {
            bail!(
                "{} changed files during checkpoint and is still running; \
                 close it before `psd unsync`",
                profile.kind.process_name()
            );
        }
        warn!(
            app = %profile.kind.as_ref(),
            "source changed after the app exited; retrying checkpoint"
        );
        sync_outcome = checkpoint::run(&paths)?;
        if sync_outcome == checkpoint::Outcome::SourceChanged {
            bail!(
                "{} kept changing during persistence; refusing to unmount",
                paths.dir.display()
            );
        }
    }

    // This is a guard for an explicit destructive command, not a
    // synchronization primitive: automatic systemd stop only checkpoints.
    if app_running(profile.kind, &state.user)? {
        bail!(
            "{} is running; close it before `psd unsync`",
            profile.kind.process_name()
        );
    }

    // Durable first; a failure from here on leaves the session fully
    // live.
    fsync_dir(&paths.back_ovfs)?;

    // Unmount first: EBUSY then bails while the session is still
    // intact.
    overlay::unmount(&paths.tmp)?;

    fs::remove_file(&paths.dir)
        .with_context(|| format!("unlink {}", paths.dir.display()))?;
    // Best-effort: durable state is in BACK_OVFS, and tmpfs dies on
    // reboot anyway.
    let _ = remove_dir_all(&paths.tmp);
    let _ = remove_dir_all(&paths.upper);
    let _ = remove_dir_all(&paths.work);

    // The mirror replaces DIR wholesale -- atomic, no merge pass.
    fs::rename(&paths.back_ovfs, &paths.dir).with_context(|| {
        format!(
            "rename {} -> {}",
            paths.back_ovfs.display(),
            paths.dir.display()
        )
    })?;
    fsync_parent(&paths.dir)?;
    if let Err(error) = checkpoint::remove_marker(&paths.dir) {
        warn!(
            marker = %paths.dir.join(checkpoint::MARKER_NAME).display(),
            error = %format_args!("{error:#}"),
            "plain profile restored but checkpoint marker could not be removed"
        );
    }
    if let Err(error) = checkpoint::remove_legacy_marker(&paths) {
        warn!(
            marker = %paths.legacy_back_ovfs_committed.display(),
            error = %format_args!("{error:#}"),
            "plain profile restored but legacy marker could not be removed"
        );
    }
    if let Err(error) = checkpoint::discard_staging(&paths) {
        warn!(
            staging = %paths.back_ovfs_stage.display(),
            error = %format_args!("{error:#}"),
            "plain profile restored but stale staging could not be removed"
        );
    }
    // Superseded. Removal failure is non-fatal: the next startup
    // rotates a stale BACKUP aside.
    if paths.backup.exists()
        && let Err(e) = fs::remove_dir_all(&paths.backup)
    {
        warn!(
            dir = %paths.backup.display(),
            error = ?e,
            "failed to remove superseded backup"
        );
    }

    info!(app = %profile.kind.as_ref(), "unsync ok");
    Ok(UnsyncOutcome::TornDown)
}

/// Copy permission bits from `src` to `dst`.
fn copy_mode(src: &Path, dst: &Path) -> Result<()> {
    use std::os::unix::fs::PermissionsExt as _;
    let mode = fs::metadata(src)
        .with_context(|| format!("stat {}", src.display()))?
        .permissions()
        .mode();
    fs::set_permissions(dst, fs::Permissions::from_mode(mode))
        .with_context(|| format!("chmod {}", dst.display()))?;
    Ok(())
}

fn fsync_parent(path: &Path) -> Result<()> {
    let parent = path.parent().with_context(|| {
        format!("{} has no parent directory", path.display())
    })?;
    fsync_dir(parent)
}

fn next_stale_backup(backup: &Path) -> Result<PathBuf> {
    for index in 0..1024 {
        let suffix = if index == 0 {
            "-stale".to_owned()
        } else {
            format!("-stale-{index}")
        };
        let candidate = append_suffix(backup, &suffix);
        if metadata_if_exists(&candidate)?.is_none() {
            return Ok(candidate);
        }
    }
    bail!(
        "too many stale backups beside {}; clean them up manually",
        backup.display()
    )
}

fn metadata_if_exists(path: &Path) -> Result<Option<fs::Metadata>> {
    match fs::symlink_metadata(path) {
        Ok(metadata) => Ok(Some(metadata)),
        Err(error) if error.kind() == ErrorKind::NotFound => Ok(None),
        Err(error) => Err(error)
            .with_context(|| format!("inspect {}", path.display())),
    }
}

fn fsync_dir(dir_path: &Path) -> Result<()> {
    let file = fs::File::open(dir_path)
        .with_context(|| format!("open {}", dir_path.display()))?;
    match file.sync_all() {
        Ok(()) => Ok(()),
        // Some filesystems reject fsync on directories.
        Err(error) if error.kind() == ErrorKind::InvalidInput => {
            warn!(
                dir = %dir_path.display(),
                "filesystem does not support syncing directories"
            );
            Ok(())
        }
        Err(error) => Err(error)
            .with_context(|| format!("fsync {}", dir_path.display())),
    }
}

#[cfg(test)]
#[expect(clippy::unwrap_used, reason = "Tests")]
mod tests {
    use std::fs::create_dir;

    use super::*;

    use tempfile::tempdir;

    #[test]
    fn stale_backup_rotation_never_clobbers_an_existing_generation() {
        let temp = tempdir().unwrap();
        let backup = temp.path().join("profile-backup");
        create_dir(append_suffix(&backup, "-stale")).unwrap();
        create_dir(append_suffix(&backup, "-stale-1")).unwrap();

        assert_eq!(
            next_stale_backup(&backup).unwrap(),
            append_suffix(&backup, "-stale-2")
        );
    }
}
