//! Sync state machine: startup / resync / unsync.
//!
//! ```text
//! Active session:
//!   DIR  --symlink--> TMP (overlay mount)
//!   BACKUP           = frozen lowerdir (read-only while mounted)
//!   UPPER (tmpfs)    = overlay writes (the delta)
//!   BACK_OVFS (disk) = staging for periodic resyncs
//! ```
//!
//! Invariants:
//!
//! - Commands converge: a profile already in the target state is a
//!   success, not an error. NixOS switches reload the owning systemd
//!   unit without killing its FUSE daemons; explicit stop/start cycles
//!   still recover from every completed filesystem transition.
//! - Never write a lowerdir (`BACKUP`) while its overlay is mounted.
//! - Never tear down under a running app: unsync persists the delta
//!   and leaves the profile live instead of failing.
//! - Unsync promotes `BACK_OVFS` -- a complete mirror -- to `DIR` with
//!   an atomic rename, fsynced first so a crash mid-unsync leaves it
//!   consistent for recovery.
//! - Unmount before unlinking `DIR`, and verify the postcondition before
//!   advancing to the next transition.
//!
//! ## TODO: dirty tracking
//!
//! Unsync rescans the whole profile even when clean; tracking overlay
//! writes would skip that scan.

use std::env;
use std::fs;
use std::fs::remove_dir_all;
use std::io::ErrorKind;
use std::io::Write as _;
use std::os::unix::fs::symlink;
use std::path::Path;
use std::path::PathBuf;
use std::process::Command;

use anyhow::Context as _;
use anyhow::Result;
use anyhow::bail;
use rustix::fs::CWD;
use rustix::fs::RenameFlags;
use rustix::fs::renameat_with;
use tracing::debug;
use tracing::info;
use tracing::warn;

use crate::apps::AppKind;
use crate::apps::AppProfile;
use crate::apps::ProcessMatch;
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

    // Tmpfs dirs inherit DIR's mode.
    for directory in [&paths.tmp, &paths.upper, &paths.work] {
        if !directory.exists() {
            fs::create_dir_all(directory).with_context(|| {
                format!("mkdir {}", directory.display())
            })?;
            copy_mode(&paths.dir, directory)?;
        }
    }

    if paths.backup.exists() {
        // Stale backup from a failed startup: rotate aside, never clobber.
        warn!(
            backup = %paths.backup.display(),
            "stale BACKUP exists; moving aside (prior startup failed?)"
        );
        let aside = append_suffix(&paths.backup, "-stale");
        fs::rename(&paths.backup, &aside).with_context(|| {
            format!("rename stale backup {}", paths.backup.display())
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
enum RsyncOutcome {
    Complete,
    /// A source entry vanished while the live application was mutating it.
    SourceChanged,
}

/// Resync: refresh `BACK_OVFS` from the overlay view. Safe while
/// mounted -- the target sits outside the overlay. Non-live profiles
/// are skipped.
pub fn resync(state: &State, profile: &AppProfile) -> Result<()> {
    let paths = state.paths_for(profile);
    if !overlay_live(&paths)? {
        debug!(dir = %paths.dir.display(), "not live; skipping resync");
        return Ok(());
    }
    match checkpoint(&paths)? {
        RsyncOutcome::Complete => {
            info!(app = %profile.kind.as_ref(), "resync ok");
        }
        RsyncOutcome::SourceChanged => {
            warn!(
                app = %profile.kind.as_ref(),
                dir = %paths.dir.display(),
                "profile changed during resync; keeping the overlay live and \
                 retrying on the next scheduled resync"
            );
        }
    }
    Ok(())
}

/// Per-profile result of [`unsync`].
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum UnsyncOutcome {
    /// Torn down; the profile is back on disk as a plain directory.
    TornDown,
    /// App running: delta persisted, overlay left live.
    LeftLive,
    /// Not live; nothing to do.
    Skipped,
}

/// Unsync: persist the delta to `BACK_OVFS`, then tear down -- or
/// leave the profile live if the app is running. Non-live profiles
/// are a no-op.
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
    let mut sync_outcome = checkpoint(&paths)?;
    if sync_outcome == RsyncOutcome::SourceChanged {
        if app_running(profile.kind, &state.user)? {
            warn!(
                app = %profile.kind.as_ref(),
                dir = %paths.dir.display(),
                "app changed files during persistence; no partial checkpoint \
                 promoted and overlay left live"
            );
            return Ok(UnsyncOutcome::LeftLive);
        }
        warn!(
            app = %profile.kind.as_ref(),
            "source changed during persistence after the app exited; retrying"
        );
        sync_outcome = checkpoint(&paths)?;
        if sync_outcome == RsyncOutcome::SourceChanged {
            bail!(
                "{} kept changing during persistence; refusing to unmount",
                paths.dir.display()
            );
        }
    }

    // Busy: leave live (tearing down under a writer corrupts state).
    if app_running(profile.kind, &state.user)? {
        warn!(
            app = %profile.kind.as_ref(),
            dir = %paths.dir.display(),
            "app running; delta persisted, leaving overlay live"
        );
        return Ok(UnsyncOutcome::LeftLive);
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
    if let Err(error) = remove_managed_file(&paths.back_ovfs_committed) {
        warn!(
            marker = %paths.back_ovfs_committed.display(),
            error = %format_args!("{error:#}"),
            "plain profile restored but checkpoint marker could not be removed"
        );
    }
    if let Err(error) = discard_staging(&paths) {
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

/// Build a fresh mirror and publish it only after a complete transfer.
fn checkpoint(paths: &ProfilePaths) -> Result<RsyncOutcome> {
    prepare_staging(paths)?;
    let outcome = match rsync_to_staging(paths) {
        Ok(outcome) => outcome,
        Err(error) => {
            return match discard_staging(paths) {
                Ok(()) => Err(error),
                Err(cleanup_error) => Err(error.context(format!(
                    "also failed to discard incomplete checkpoint: \
                     {cleanup_error:#}"
                ))),
            };
        }
    };

    if outcome == RsyncOutcome::SourceChanged {
        discard_staging(paths)?;
        return Ok(outcome);
    }

    commit_staging(paths)?;
    Ok(RsyncOutcome::Complete)
}

fn prepare_staging(paths: &ProfilePaths) -> Result<()> {
    discard_staging(paths)?;
    fs::create_dir(&paths.back_ovfs_stage).with_context(|| {
        format!("mkdir {}", paths.back_ovfs_stage.display())
    })?;
    let _ = plain_directory_exists(&paths.back_ovfs)?;
    Ok(())
}

/// Transfer into an empty sibling. `--link-dest` reuses unchanged files
/// without allowing an interrupted run to mutate the committed mirror.
fn rsync_to_staging(paths: &ProfilePaths) -> Result<RsyncOutcome> {
    let mut command = Command::new("rsync");
    command.args([
        "-aX",
        "--checksum",
        "--checksum-choice=xxh128",
        "--fsync",
    ]);
    if plain_directory_exists(&paths.back_ovfs)? {
        command.arg(format!("--link-dest={}", paths.back_ovfs.display()));
    }
    command
        .arg(format!("{}/", paths.dir.display()))
        .arg(&paths.back_ovfs_stage);
    debug!(cmd = ?command, "rsync checkpoint");
    let output = exec::output(&mut command).with_context(|| {
        format!(
            "rsync {} -> {}",
            paths.dir.display(),
            paths.back_ovfs_stage.display()
        )
    })?;
    match accepted_rsync_outcome(output.status.code()) {
        Some(RsyncOutcome::Complete) => Ok(RsyncOutcome::Complete),
        Some(RsyncOutcome::SourceChanged) => {
            warn!(
                src = %paths.dir.display(),
                staging = %paths.back_ovfs_stage.display(),
                detail = %String::from_utf8_lossy(&output.stderr).trim(),
                "rsync source changed; discarding incomplete checkpoint"
            );
            Ok(RsyncOutcome::SourceChanged)
        }
        None => bail!(
            "rsync {} -> {} failed (exit {}): {}",
            paths.dir.display(),
            paths.back_ovfs_stage.display(),
            output.status.code().unwrap_or(-1),
            String::from_utf8_lossy(&output.stderr).trim()
        ),
    }
}

fn commit_staging(paths: &ProfilePaths) -> Result<()> {
    fsync_dir(&paths.back_ovfs_stage)?;
    if plain_directory_exists(&paths.back_ovfs)? {
        renameat_with(
            CWD,
            &paths.back_ovfs_stage,
            CWD,
            &paths.back_ovfs,
            RenameFlags::EXCHANGE,
        )
        .with_context(|| {
            format!(
                "atomically exchange {} and {}",
                paths.back_ovfs_stage.display(),
                paths.back_ovfs.display()
            )
        })?;
    } else {
        fs::rename(&paths.back_ovfs_stage, &paths.back_ovfs)
            .with_context(|| {
                format!(
                    "commit {} -> {}",
                    paths.back_ovfs_stage.display(),
                    paths.back_ovfs.display()
                )
            })?;
    }
    fsync_parent(&paths.back_ovfs)?;
    write_commit_marker(paths)?;

    // After an exchange the staging name contains the previous complete
    // generation. Failure to reclaim it does not invalidate the commit.
    if let Err(error) = discard_staging(paths) {
        warn!(
            staging = %paths.back_ovfs_stage.display(),
            error = %format_args!("{error:#}"),
            "checkpoint committed but previous generation could not be removed"
        );
    }
    Ok(())
}

fn write_commit_marker(paths: &ProfilePaths) -> Result<()> {
    let temporary = append_suffix(&paths.back_ovfs_committed, ".tmp");
    remove_managed_file(&temporary)?;
    let mut marker = fs::OpenOptions::new()
        .write(true)
        .create_new(true)
        .open(&temporary)
        .with_context(|| format!("create {}", temporary.display()))?;
    marker
        .write_all(b"psd-rs committed checkpoint\n")
        .with_context(|| format!("write {}", temporary.display()))?;
    marker
        .sync_all()
        .with_context(|| format!("fsync {}", temporary.display()))?;
    fs::rename(&temporary, &paths.back_ovfs_committed).with_context(
        || {
            format!(
                "commit marker {} -> {}",
                temporary.display(),
                paths.back_ovfs_committed.display()
            )
        },
    )?;
    fsync_parent(&paths.back_ovfs_committed)
}

fn discard_staging(paths: &ProfilePaths) -> Result<()> {
    remove_managed_directory(&paths.back_ovfs_stage)
}

fn remove_managed_directory(path: &Path) -> Result<()> {
    match fs::symlink_metadata(path) {
        Ok(metadata) if metadata.is_dir() => fs::remove_dir_all(path)
            .with_context(|| format!("remove {}", path.display())),
        Ok(_) => {
            bail!("{} is not psd's staging directory", path.display())
        }
        Err(error) if error.kind() == ErrorKind::NotFound => Ok(()),
        Err(error) => Err(error)
            .with_context(|| format!("inspect {}", path.display())),
    }
}

fn plain_directory_exists(path: &Path) -> Result<bool> {
    match fs::symlink_metadata(path) {
        Ok(metadata) if metadata.is_dir() => Ok(true),
        Ok(_) => bail!("{} is not a plain directory", path.display()),
        Err(error) if error.kind() == ErrorKind::NotFound => Ok(false),
        Err(error) => Err(error)
            .with_context(|| format!("inspect {}", path.display())),
    }
}

fn fsync_parent(path: &Path) -> Result<()> {
    let parent = path.parent().with_context(|| {
        format!("{} has no parent directory", path.display())
    })?;
    fsync_dir(parent)
}

fn remove_managed_file(path: &Path) -> Result<()> {
    match fs::symlink_metadata(path) {
        Ok(metadata) if metadata.is_file() => fs::remove_file(path)
            .with_context(|| format!("remove {}", path.display())),
        Ok(_) => bail!("{} is not psd's marker file", path.display()),
        Err(error) if error.kind() == ErrorKind::NotFound => Ok(()),
        Err(error) => Err(error)
            .with_context(|| format!("inspect {}", path.display())),
    }
}

/// rsync(1) exit 24 means source files vanished during transfer. That is
/// routine for a live browser profile, not an I/O failure.
fn accepted_rsync_outcome(code: Option<i32>) -> Option<RsyncOutcome> {
    match code {
        Some(0) => Some(RsyncOutcome::Complete),
        Some(24) => Some(RsyncOutcome::SourceChanged),
        Some(_) | None => None,
    }
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
    use std::fs::create_dir_all;
    use std::fs::read;
    use std::fs::write;

    use super::*;

    use tempfile::tempdir;

    use crate::apps::AppKind;

    fn make_paths(root: &Path) -> ProfilePaths {
        let profile = AppProfile {
            kind: AppKind::Firefox,
            user: "user".to_owned(),
            path: root.join("profile"),
            suffix: "profile".to_owned(),
        };
        ProfilePaths::new(&profile, root)
    }

    #[test]
    fn vanished_live_files_are_a_retryable_rsync_outcome() {
        assert_eq!(
            accepted_rsync_outcome(Some(24)),
            Some(RsyncOutcome::SourceChanged)
        );
        assert_eq!(
            accepted_rsync_outcome(Some(0)),
            Some(RsyncOutcome::Complete)
        );
        assert_eq!(accepted_rsync_outcome(Some(23)), None);
        assert_eq!(accepted_rsync_outcome(None), None);
    }

    #[test]
    fn commit_atomically_replaces_the_previous_mirror() {
        let temp = tempdir().unwrap();
        let paths = make_paths(temp.path());
        create_dir_all(&paths.back_ovfs).unwrap();
        write(paths.back_ovfs.join("data"), b"old").unwrap();
        create_dir_all(&paths.back_ovfs_stage).unwrap();
        write(paths.back_ovfs_stage.join("data"), b"new").unwrap();

        commit_staging(&paths).unwrap();

        assert_eq!(read(paths.back_ovfs.join("data")).unwrap(), b"new");
        assert!(paths.back_ovfs_committed.is_file());
        assert!(!paths.back_ovfs_stage.exists());
    }
}
