//! Ungraceful-state normalization.
//!
//! A stopped FUSE daemon can leave `DIR` pointing to an ordinary `TMP`
//! directory, so symlink resolution alone does not prove a session is live.
//! Recovery classifies both the directory entry and the actual mount before
//! touching data. It restores the newer durable copy and clears stale tmpfs
//! state before another overlay is mounted.

use std::fs;
use std::io::ErrorKind;
use std::os::unix::fs::symlink;
use std::path::Path;
use std::time::SystemTime;

use anyhow::Context as _;
use anyhow::Result;
use anyhow::bail;
use tracing::info;
use tracing::warn;

use crate::checkpoint;
use crate::overlay;
use crate::paths::ProfilePaths;
use crate::paths::SessionState;

/// What [`recover`] found.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum RecoverOutcome {
    /// An unmounted session was restored as a plain profile directory.
    Recovered,
    /// A mounted overlay missing only its app-visible symlink was reattached.
    Reattached,
    /// A disconnected FUSE mount was remounted with its existing upperdir.
    Reconnected,
    /// `DIR` was already a plain profile directory.
    Already,
    /// The overlay and its managed symlink are live.
    Live,
    /// No profile data exists; a stale managed symlink was removed.
    Absent,
}

/// Normalize ungraceful state for one profile; healthy profiles are a no-op.
pub fn recover(paths: &ProfilePaths) -> Result<RecoverOutcome> {
    recover_state(paths, paths.session_state()?)
}

fn recover_state(
    paths: &ProfilePaths,
    state: SessionState,
) -> Result<RecoverOutcome> {
    match state {
        SessionState::Live => return Ok(RecoverOutcome::Live),
        SessionState::OrphanMount => {
            symlink(&paths.tmp, &paths.dir).with_context(|| {
                format!(
                    "reattach {} -> {}",
                    paths.dir.display(),
                    paths.tmp.display()
                )
            })?;
            info!(
                dir = %paths.dir.display(),
                tmp = %paths.tmp.display(),
                "reattached orphaned overlay"
            );
            return Ok(RecoverOutcome::Reattached);
        }
        SessionState::DisconnectedMount => {
            reconnect_disconnected(paths)?;
            return Ok(RecoverOutcome::Reconnected);
        }
        SessionState::PlainDirectory => {
            ensure_empty_unmounted_mountpoint(paths)?;
            checkpoint::discard_staging(paths)?;
            checkpoint::remove_marker(&paths.dir)?;
            if !paths.back_ovfs.exists() {
                checkpoint::remove_legacy_marker(paths)?;
            }
            cleanup_runtime(paths)?;
            return Ok(RecoverOutcome::Already);
        }
        SessionState::Missing | SessionState::StaleSymlink => {}
    }
    ensure_empty_unmounted_mountpoint(paths)?;
    // A killed resync may leave a partial staging tree. It is never a
    // recovery source.
    checkpoint::discard_staging(paths)?;

    // Validate recovery artifacts before unlinking the app-visible path.
    let target = pick_recovery_target(paths)?;

    if state == SessionState::StaleSymlink {
        fs::remove_file(&paths.dir).with_context(|| {
            format!("unlink stale {}", paths.dir.display())
        })?;
    }

    let Some(target) = target else {
        remove_directory_if_present(&paths.back_ovfs)?;
        checkpoint::remove_legacy_marker(paths)?;
        cleanup_runtime(paths)?;
        if state == SessionState::StaleSymlink {
            warn!(
                dir = %paths.dir.display(),
                "stale managed symlink had no durable profile to restore"
            );
        }
        return Ok(RecoverOutcome::Absent);
    };

    info!(
        dir = %paths.dir.display(),
        source = %target.display(),
        "ungraceful state detected, recovering"
    );
    let other = if target == paths.backup {
        &paths.back_ovfs
    } else {
        &paths.backup
    };

    fs::rename(target, &paths.dir).with_context(|| {
        format!("rename {} -> {}", target.display(), paths.dir.display())
    })?;
    remove_directory_if_present(other)?;
    checkpoint::remove_marker(&paths.dir)?;
    checkpoint::remove_legacy_marker(paths)?;
    cleanup_runtime(paths)?;

    Ok(RecoverOutcome::Recovered)
}

fn reconnect_disconnected(paths: &ProfilePaths) -> Result<()> {
    let link_missing = managed_link_missing(paths)?;
    for directory in [&paths.backup, &paths.upper, &paths.work] {
        require_plain_directory(directory)?;
    }

    warn!(
        dir = %paths.dir.display(),
        tmp = %paths.tmp.display(),
        upper = %paths.upper.display(),
        "FUSE daemon exited; reconnecting the existing overlay without \
         discarding its in-memory delta"
    );
    overlay::unmount(&paths.tmp)
        .context("detach disconnected FUSE mount")?;

    match fs::symlink_metadata(&paths.tmp) {
        Ok(metadata) if metadata.is_dir() => {}
        Ok(_) => {
            bail!(
                "{} is not a plain mountpoint after detaching the \
                 disconnected overlay",
                paths.tmp.display()
            );
        }
        Err(error) if error.kind() == ErrorKind::NotFound => {
            fs::create_dir_all(&paths.tmp).with_context(|| {
                format!("recreate mountpoint {}", paths.tmp.display())
            })?;
        }
        Err(error) => {
            return Err(error).with_context(|| {
                format!(
                    "inspect detached mountpoint {}",
                    paths.tmp.display()
                )
            });
        }
    }

    overlay::mount(&paths.backup, &paths.upper, &paths.work, &paths.tmp)
        .context("remount existing overlay state")?;
    if link_missing {
        symlink(&paths.tmp, &paths.dir).with_context(|| {
            format!(
                "reattach {} -> {}",
                paths.dir.display(),
                paths.tmp.display()
            )
        })?;
    }

    info!(
        dir = %paths.dir.display(),
        tmp = %paths.tmp.display(),
        "reconnected disconnected overlay"
    );
    Ok(())
}

fn managed_link_missing(paths: &ProfilePaths) -> Result<bool> {
    let metadata = match fs::symlink_metadata(&paths.dir) {
        Ok(metadata) => metadata,
        Err(error) if error.kind() == ErrorKind::NotFound => {
            return Ok(true);
        }
        Err(error) => {
            return Err(error).with_context(|| {
                format!("inspect {}", paths.dir.display())
            });
        }
    };
    if !metadata.file_type().is_symlink() {
        bail!(
            "{} is not psd's managed symlink; refusing to reconnect over it",
            paths.dir.display()
        );
    }
    let target = fs::read_link(&paths.dir).with_context(|| {
        format!("read symlink {}", paths.dir.display())
    })?;
    if target != paths.tmp {
        bail!(
            "{} points to {}, not psd's expected {}; refusing to reconnect",
            paths.dir.display(),
            target.display(),
            paths.tmp.display()
        );
    }
    Ok(false)
}

fn require_plain_directory(path: &Path) -> Result<()> {
    let metadata = fs::symlink_metadata(path).with_context(|| {
        format!("inspect required directory {}", path.display())
    })?;
    if !metadata.is_dir() {
        bail!("{} is not a plain directory", path.display());
    }
    Ok(())
}

/// Prefer a checkpoint explicitly committed by the current implementation.
/// Without a marker, retain the legacy mtime heuristic for migration.
fn pick_recovery_target(paths: &ProfilePaths) -> Result<Option<&Path>> {
    let checkpoint_committed = checkpoint::is_committed(paths)?;
    let frozen_mtime = directory_mtime(&paths.backup, false)?;
    let mirror_mtime =
        directory_mtime(&paths.back_ovfs, !checkpoint_committed)?;
    if checkpoint_committed && mirror_mtime.is_some() {
        return Ok(Some(&paths.back_ovfs));
    }
    Ok(match (frozen_mtime, mirror_mtime) {
        (None, None) => None,
        (None, Some(_)) => Some(&paths.back_ovfs),
        // Legacy mirrors had no commit marker. Ties go to the periodic
        // mirror, which was never intentionally older than the lowerdir.
        (Some(frozen_time), Some(mirror_time))
            if mirror_time >= frozen_time =>
        {
            Some(&paths.back_ovfs)
        }
        (Some(_), _) => Some(&paths.backup),
    })
}

fn directory_mtime(
    path: &Path,
    reject_empty: bool,
) -> Result<Option<SystemTime>> {
    let metadata = match fs::symlink_metadata(path) {
        Ok(metadata) => metadata,
        Err(error) if error.kind() == ErrorKind::NotFound => {
            return Ok(None);
        }
        Err(error) => {
            return Err(error)
                .with_context(|| format!("inspect {}", path.display()));
        }
    };
    if !metadata.is_dir() {
        bail!("{} is not a plain recovery directory", path.display());
    }
    if reject_empty
        && fs::read_dir(path)
            .with_context(|| format!("read {}", path.display()))?
            .next()
            .is_none()
    {
        return Ok(None);
    }
    metadata
        .modified()
        .map(Some)
        .with_context(|| format!("read mtime for {}", path.display()))
}

fn ensure_empty_unmounted_mountpoint(paths: &ProfilePaths) -> Result<()> {
    let metadata = match fs::symlink_metadata(&paths.tmp) {
        Ok(metadata) => metadata,
        Err(error) if error.kind() == ErrorKind::NotFound => return Ok(()),
        Err(error) => {
            return Err(error).with_context(|| {
                format!("inspect {}", paths.tmp.display())
            });
        }
    };
    if !metadata.is_dir() {
        bail!(
            "unmounted runtime path {} is not a directory",
            paths.tmp.display()
        );
    }
    if fs::read_dir(&paths.tmp)
        .with_context(|| format!("read {}", paths.tmp.display()))?
        .next()
        .transpose()
        .with_context(|| format!("read entry in {}", paths.tmp.display()))?
        .is_some()
    {
        bail!(
            "{} contains data after its overlay disappeared; refusing \
             recovery to preserve possible post-unmount writes",
            paths.tmp.display()
        );
    }
    Ok(())
}

fn remove_directory_if_present(path: &Path) -> Result<()> {
    match fs::symlink_metadata(path) {
        Ok(metadata) if metadata.is_dir() => fs::remove_dir_all(path)
            .with_context(|| format!("remove {}", path.display())),
        Ok(_) => {
            bail!("{} is not psd's managed directory", path.display())
        }
        Err(error) if error.kind() == ErrorKind::NotFound => Ok(()),
        Err(error) => Err(error)
            .with_context(|| format!("inspect {}", path.display())),
    }
}

fn cleanup_runtime(paths: &ProfilePaths) -> Result<()> {
    for path in [&paths.tmp, &paths.upper, &paths.work] {
        remove_directory_if_present(path)?;
    }
    Ok(())
}

#[cfg(test)]
#[expect(clippy::unwrap_used, reason = "Tests")]
mod tests {
    use std::fs::create_dir_all;
    use std::fs::write;
    use std::thread::sleep;
    use std::time::Duration;

    use super::*;

    use tempfile::tempdir;

    use crate::apps::AppKind;
    use crate::apps::AppProfile;
    use crate::overlay::MountState;

    /// Build real paths so tests track the actual naming scheme.
    fn make_paths(root: &Path) -> ProfilePaths {
        let profile = AppProfile {
            kind: AppKind::Firefox,
            user: "u".to_owned(),
            path: root.join("dir"),
            suffix: "dir".to_owned(),
        };
        ProfilePaths::new(&profile, root)
    }

    fn recover_with_mount(
        paths: &ProfilePaths,
        overlay_mounted: bool,
    ) -> Result<RecoverOutcome> {
        let mount_state = if overlay_mounted {
            MountState::Mounted
        } else {
            MountState::Unmounted
        };
        recover_state(paths, paths.classify_session(mount_state)?)
    }

    fn make_managed_symlink(paths: &ProfilePaths) {
        symlink(&paths.tmp, &paths.dir).unwrap();
    }

    #[test]
    fn live_symlink_is_noop() {
        let temp = tempdir().unwrap();
        let paths = make_paths(temp.path());
        create_dir_all(&paths.tmp).unwrap();
        make_managed_symlink(&paths);

        assert_eq!(
            recover_with_mount(&paths, true).unwrap(),
            RecoverOutcome::Live
        );
        assert!(paths.dir.is_symlink());
    }

    #[test]
    fn resolving_stale_symlink_is_recovered() {
        let temp = tempdir().unwrap();
        let paths = make_paths(temp.path());
        create_dir_all(&paths.tmp).unwrap();
        create_dir_all(&paths.backup).unwrap();
        write(paths.backup.join("data"), b"saved").unwrap();
        make_managed_symlink(&paths);

        assert_eq!(
            recover_with_mount(&paths, false).unwrap(),
            RecoverOutcome::Recovered
        );
        assert_eq!(
            fs::read(paths.dir.join("data")).unwrap(),
            b"saved".as_slice()
        );
        assert!(!paths.dir.is_symlink());
        assert!(!paths.tmp.exists());
    }

    #[test]
    fn stale_mountpoint_writes_are_preserved() {
        let temp = tempdir().unwrap();
        let paths = make_paths(temp.path());
        create_dir_all(&paths.tmp).unwrap();
        write(paths.tmp.join("late-write"), b"new").unwrap();
        create_dir_all(&paths.backup).unwrap();
        write(paths.backup.join("data"), b"saved").unwrap();
        make_managed_symlink(&paths);

        let error = recover_with_mount(&paths, false).unwrap_err();
        assert!(error.to_string().contains("post-unmount writes"));
        assert!(paths.dir.is_symlink());
        assert!(paths.tmp.join("late-write").exists());
        assert!(paths.backup.exists());
    }

    #[test]
    fn dangling_picks_newer_back_ovfs() {
        let temp = tempdir().unwrap();
        let paths = make_paths(temp.path());
        create_dir_all(&paths.backup).unwrap();
        write(paths.backup.join("data"), b"old").unwrap();
        sleep(Duration::from_millis(10));
        create_dir_all(&paths.back_ovfs).unwrap();
        write(paths.back_ovfs.join("data"), b"new").unwrap();
        make_managed_symlink(&paths);

        assert_eq!(
            recover_with_mount(&paths, false).unwrap(),
            RecoverOutcome::Recovered
        );
        assert_eq!(
            fs::read(paths.dir.join("data")).unwrap(),
            b"new".as_slice()
        );
        assert!(!paths.back_ovfs.exists());
        assert!(!paths.backup.exists());
    }

    #[test]
    fn committed_checkpoint_beats_legacy_mtime_heuristic() {
        let temp = tempdir().unwrap();
        let paths = make_paths(temp.path());
        create_dir_all(&paths.back_ovfs).unwrap();
        write(paths.back_ovfs.join("data"), b"committed").unwrap();
        write(paths.back_ovfs.join(checkpoint::MARKER_NAME), b"committed")
            .unwrap();
        sleep(Duration::from_millis(10));
        create_dir_all(&paths.backup).unwrap();
        write(paths.backup.join("data"), b"newer-mtime").unwrap();
        make_managed_symlink(&paths);

        assert_eq!(
            recover_with_mount(&paths, false).unwrap(),
            RecoverOutcome::Recovered
        );
        assert_eq!(
            fs::read(paths.dir.join("data")).unwrap(),
            b"committed".as_slice()
        );
        assert!(!paths.dir.join(checkpoint::MARKER_NAME).exists());
    }

    #[test]
    fn empty_back_ovfs_falls_back_to_backup() {
        let temp = tempdir().unwrap();
        let paths = make_paths(temp.path());
        create_dir_all(&paths.backup).unwrap();
        write(paths.backup.join("data"), b"old").unwrap();
        create_dir_all(&paths.back_ovfs).unwrap();
        make_managed_symlink(&paths);

        assert_eq!(
            recover_with_mount(&paths, false).unwrap(),
            RecoverOutcome::Recovered
        );
        assert_eq!(
            fs::read(paths.dir.join("data")).unwrap(),
            b"old".as_slice()
        );
        assert!(!paths.back_ovfs.exists());
    }

    #[test]
    fn lone_back_ovfs_is_recovered() {
        let temp = tempdir().unwrap();
        let paths = make_paths(temp.path());
        create_dir_all(&paths.back_ovfs).unwrap();
        write(paths.back_ovfs.join("data"), b"saved").unwrap();
        make_managed_symlink(&paths);

        assert_eq!(
            recover_with_mount(&paths, false).unwrap(),
            RecoverOutcome::Recovered
        );
        assert_eq!(
            fs::read(paths.dir.join("data")).unwrap(),
            b"saved".as_slice()
        );
    }

    #[test]
    fn missing_copies_remove_stale_symlink() {
        let temp = tempdir().unwrap();
        let paths = make_paths(temp.path());
        make_managed_symlink(&paths);

        assert_eq!(
            recover_with_mount(&paths, false).unwrap(),
            RecoverOutcome::Absent
        );
        paths.dir.symlink_metadata().unwrap_err();
    }

    #[test]
    fn orphan_mount_is_reattached() {
        let temp = tempdir().unwrap();
        let paths = make_paths(temp.path());
        create_dir_all(&paths.tmp).unwrap();

        assert_eq!(
            recover_with_mount(&paths, true).unwrap(),
            RecoverOutcome::Reattached
        );
        assert_eq!(fs::read_link(&paths.dir).unwrap(), paths.tmp);
    }

    #[test]
    fn unrelated_symlink_is_never_removed() {
        let temp = tempdir().unwrap();
        let paths = make_paths(temp.path());
        let unrelated = temp.path().join("unrelated");
        create_dir_all(&unrelated).unwrap();
        symlink(&unrelated, &paths.dir).unwrap();

        let error =
            paths.classify_session(MountState::Unmounted).unwrap_err();
        assert!(error.to_string().contains("refusing to modify"));
        assert_eq!(fs::read_link(&paths.dir).unwrap(), unrelated);
    }

    #[test]
    fn disconnected_managed_symlink_is_classified_for_reconnection() {
        let temp = tempdir().unwrap();
        let paths = make_paths(temp.path());
        create_dir_all(&paths.tmp).unwrap();
        make_managed_symlink(&paths);

        assert_eq!(
            paths.classify_session(MountState::Disconnected).unwrap(),
            SessionState::DisconnectedMount
        );
    }
}
