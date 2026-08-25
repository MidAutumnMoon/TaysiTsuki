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

use crate::paths::ProfilePaths;
use crate::paths::SessionState;

/// What [`recover`] found.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum RecoverOutcome {
    /// An unmounted session was restored as a plain profile directory.
    Recovered,
    /// A mounted overlay missing only its app-visible symlink was reattached.
    Reattached,
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
        SessionState::PlainDirectory => {
            ensure_empty_unmounted_mountpoint(paths)?;
            cleanup_runtime(paths)?;
            return Ok(RecoverOutcome::Already);
        }
        SessionState::Missing | SessionState::StaleSymlink => {}
    }
    ensure_empty_unmounted_mountpoint(paths)?;

    // Validate recovery artifacts before unlinking the app-visible path.
    let target = pick_recovery_target(&paths.backup, &paths.back_ovfs)?;

    if state == SessionState::StaleSymlink {
        fs::remove_file(&paths.dir).with_context(|| {
            format!("unlink stale {}", paths.dir.display())
        })?;
    }

    let Some(target) = target else {
        remove_directory_if_present(&paths.back_ovfs)?;
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
    cleanup_runtime(paths)?;

    Ok(RecoverOutcome::Recovered)
}

/// Pick the newer complete directory. An empty `back_ovfs` cannot win:
/// startup may have created it before the first successful resync.
fn pick_recovery_target<'path>(
    backup: &'path Path,
    back_ovfs: &'path Path,
) -> Result<Option<&'path Path>> {
    let frozen_mtime = directory_mtime(backup, false)?;
    let mirror_mtime = directory_mtime(back_ovfs, true)?;
    Ok(match (frozen_mtime, mirror_mtime) {
        (None, None) => None,
        (None, Some(_)) => Some(back_ovfs),
        // Ties go to `back_ovfs`: it is the periodic mirror and therefore
        // never intentionally older than the frozen lowerdir.
        (Some(frozen_time), Some(mirror_time))
            if mirror_time >= frozen_time =>
        {
            Some(back_ovfs)
        }
        (Some(_), _) => Some(backup),
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
    match fs::remove_dir_all(path) {
        Ok(()) => Ok(()),
        Err(error) if error.kind() == ErrorKind::NotFound => Ok(()),
        Err(error) => Err(error)
            .with_context(|| format!("remove {}", path.display())),
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
        recover_state(paths, paths.classify_session(overlay_mounted)?)
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

        let error = paths.classify_session(false).unwrap_err();
        assert!(error.to_string().contains("refusing to modify"));
        assert_eq!(fs::read_link(&paths.dir).unwrap(), unrelated);
    }
}
