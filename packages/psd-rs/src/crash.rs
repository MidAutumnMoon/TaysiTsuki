//! Ungraceful state normalization.
//!
//! After a crash, `DIR` is a dangling symlink (tmpfs gone) while `BACKUP`
//! still exists on disk. This makes remounting impossible, so we must
//! normalize before startup.
//!
//! Healthy states are no-ops: a real `DIR` (never managed, or unsync
//! completed) and a live symlink (session is up) are both left alone.
//!
//! We deliberately do NOT snapshot before recovery: it doesn't protect
//! against the likely failures (wrong pick, recovery bug, post-launch
//! corruption -- backups cover that), and a full copy of the profile per
//! recovery is pure overhead. Max data loss is one resync interval.
//!
//! Recovery logic:
//! 1. Detect dangling `DIR` (symlink to missing tmpfs) or missing `DIR`
//! 2. Pick the newer of `BACKUP` / `BACK_OVFS` (rejecting empty `BACK_OVFS`)
//! 3. Rename the picked target to `DIR`
//! 4. Delete the other

use std::fs;
use std::path::Path;
use std::time::SystemTime;

use anyhow::Context;
use anyhow::Result;
use tracing::info;
use tracing::warn;

use crate::paths::ProfilePaths;

/// Detect and normalize ungraceful state for one profile.
///
/// Returns `true` if recovery was performed.
pub fn recover(paths: &ProfilePaths) -> Result<bool> {
    // A real (non-symlink) DIR means unsync completed or psd never ran.
    // Note: `is_dir()` follows symlinks, so we check `!is_symlink()` too.
    if paths.dir.is_dir() && !paths.dir.is_symlink() {
        return Ok(false);
    }

    // DIR is a symlink resolving to an existing path: the session is
    // live and healthy. Nothing to recover -- and nothing we may
    // safely touch.
    if paths.dir.is_symlink() && paths.dir.exists() {
        return Ok(false);
    }

    // DIR is a dangling symlink (or missing). BACKUP must exist for recovery.
    if !paths.backup.exists() {
        if paths.dir.is_symlink() {
            // Dangling symlink with no backup: just remove the symlink so
            // the app recreates the profile from scratch on next launch.
            warn!(
                dir = %paths.dir.display(),
                "dangling symlink with no backup; removing symlink"
            );
            std::fs::remove_file(&paths.dir).with_context(|| {
                format!("unlink {}", paths.dir.display())
            })?;
        }
        return Ok(false);
    }

    info!(dir = %paths.dir.display(), "ungraceful state detected, recovering");

    // Remove the dangling symlink.
    if paths.dir.is_symlink() {
        std::fs::remove_file(&paths.dir).with_context(|| {
            format!("unlink dangling {}", paths.dir.display())
        })?;
    }

    // Pick the newer of BACKUP / BACK_OVFS.
    let target = pick_recovery_target(&paths.backup, &paths.back_ovfs);
    let other = if target == paths.backup {
        &paths.back_ovfs
    } else {
        &paths.backup
    };

    // Rotate the picked target into place as DIR. `target` may equal
    // `paths.backup`, so this is typically `BACKUP -> DIR`.
    fs::rename(target, &paths.dir).with_context(|| {
        format!("rename {} -> {}", target.display(), paths.dir.display())
    })?;

    // Clean up the other dir (the one we didn't pick).
    if other.exists() {
        fs::remove_dir_all(other)
            .with_context(|| format!("remove {}", other.display()))?;
    }

    Ok(true)
}

/// Pick the newer of `backup` / `back_ovfs` by mtime.
///
/// Falls back to `backup` if `back_ovfs` is missing, empty, or if
/// mtimes can't be read. An empty `back_ovfs` (e.g. from a failed
/// startup that created the dir but never resynced) must NOT be picked
/// over `backup` -- doing so would cause data loss.
fn pick_recovery_target<'a>(
    backup: &'a Path,
    back_ovfs: &'a Path,
) -> &'a Path {
    if !back_ovfs.is_dir() || is_empty_dir(back_ovfs) {
        return backup;
    }
    match (mtime(backup), mtime(back_ovfs)) {
        (Some(b), Some(o)) if o >= b => back_ovfs,
        _ => backup,
    }
}

fn mtime(p: &Path) -> Option<SystemTime> {
    fs::metadata(p).and_then(|m| m.modified()).ok()
}

fn is_empty_dir(p: &Path) -> bool {
    fs::read_dir(p).map_or(true, |mut it| it.next().is_none())
}

#[cfg(test)]
mod tests {
    use super::*;

    use tempfile::tempdir;

    fn make_paths(root: &Path) -> ProfilePaths {
        ProfilePaths {
            dir: root.join("dir"),
            backup: root.join("dir-backup"),
            back_ovfs: root.join("dir-back-ovfs"),
            tmp: root.join("dir-tmp"),
            upper: root.join("dir-rw"),
            work: root.join(".dir"),
        }
    }

    fn make_dangling(paths: &ProfilePaths) {
        // tmp never created -> symlink dangles (tmpfs gone after crash).
        std::os::unix::fs::symlink(&paths.tmp, &paths.dir).unwrap();
    }

    #[test]
    #[expect(clippy::unwrap_used)]
    fn live_symlink_is_noop() {
        let tmp = tempdir().unwrap();
        let paths = make_paths(tmp.path());
        std::fs::create_dir(&paths.tmp).unwrap();
        std::os::unix::fs::symlink(&paths.tmp, &paths.dir).unwrap();

        assert!(!recover(&paths).unwrap());
        assert!(paths.dir.is_symlink());
    }

    #[test]
    #[expect(clippy::unwrap_used)]
    fn dangling_picks_newer_back_ovfs() {
        let tmp = tempdir().unwrap();
        let paths = make_paths(tmp.path());
        std::fs::create_dir(&paths.backup).unwrap();
        std::fs::write(paths.backup.join("data"), b"old").unwrap();
        // Ensure strictly newer mtime so the pick is deterministic.
        std::thread::sleep(std::time::Duration::from_millis(10));
        std::fs::create_dir(&paths.back_ovfs).unwrap();
        std::fs::write(paths.back_ovfs.join("data"), b"new").unwrap();
        make_dangling(&paths);

        assert!(recover(&paths).unwrap());
        assert_eq!(
            std::fs::read(paths.dir.join("data")).unwrap(),
            b"new".as_slice()
        );
        assert!(!paths.back_ovfs.exists());
        assert!(!paths.backup.exists());
    }

    #[test]
    #[expect(clippy::unwrap_used)]
    fn empty_back_ovfs_falls_back_to_backup() {
        let tmp = tempdir().unwrap();
        let paths = make_paths(tmp.path());
        std::fs::create_dir(&paths.backup).unwrap();
        std::fs::write(paths.backup.join("data"), b"old").unwrap();
        std::fs::create_dir(&paths.back_ovfs).unwrap();
        make_dangling(&paths);

        assert!(recover(&paths).unwrap());
        assert_eq!(
            std::fs::read(paths.dir.join("data")).unwrap(),
            b"old".as_slice()
        );
        assert!(!paths.back_ovfs.exists());
    }

    #[test]
    #[expect(clippy::unwrap_used)]
    fn missing_backup_removes_dangling_symlink() {
        let tmp = tempdir().unwrap();
        let paths = make_paths(tmp.path());
        make_dangling(&paths);

        assert!(!recover(&paths).unwrap());
        assert!(paths.dir.symlink_metadata().is_err());
    }
}
