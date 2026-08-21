//! Ungraceful-state normalization.
//!
//! After a crash (tmpfs gone), `DIR` is a dangling symlink and the
//! real data sits in `BACKUP` / `BACK_OVFS`. Recovery restores the
//! newer of the two as `DIR`; healthy states (real `DIR`, live
//! symlink) are no-ops.
//!
//! No snapshot is taken before recovery: it wouldn't save a wrong
//! pick, and max data loss is one resync interval anyway.

use std::fs;
use std::path::Path;
use std::time::SystemTime;

use anyhow::Context;
use anyhow::Result;
use tracing::info;
use tracing::warn;

use crate::paths::ProfilePaths;

/// What [`recover`] found.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum RecoverOutcome {
    /// Ungraceful state detected and normalized.
    Recovered,
    /// Nothing to do: `DIR` is a real directory or a live symlink.
    Already,
}

/// Normalize ungraceful state for one profile; healthy profiles are
/// a no-op.
pub fn recover(paths: &ProfilePaths) -> Result<RecoverOutcome> {
    // A real directory: unsync completed or psd never ran. (`is_dir()`
    // follows symlinks, hence the explicit symlink guard.)
    if paths.dir.is_dir() && !paths.dir.is_symlink() {
        return Ok(RecoverOutcome::Already);
    }

    // Live session: nothing to recover, and nothing we may safely
    // touch.
    if paths.is_live() {
        return Ok(RecoverOutcome::Already);
    }

    // Dangling (or missing) DIR: recovery needs a backup.
    if !paths.backup.exists() {
        if paths.dir.is_symlink() {
            // Nothing to restore: drop the symlink and let the app
            // recreate its profile.
            warn!(
                dir = %paths.dir.display(),
                "dangling symlink with no backup; removing symlink"
            );
            std::fs::remove_file(&paths.dir).with_context(|| {
                format!("unlink {}", paths.dir.display())
            })?;
        }
        return Ok(RecoverOutcome::Already);
    }

    info!(dir = %paths.dir.display(), "ungraceful state detected, recovering");

    if paths.dir.is_symlink() {
        std::fs::remove_file(&paths.dir).with_context(|| {
            format!("unlink dangling {}", paths.dir.display())
        })?;
    }

    let target = pick_recovery_target(&paths.backup, &paths.back_ovfs);
    let other = if target == paths.backup {
        &paths.back_ovfs
    } else {
        &paths.backup
    };

    fs::rename(target, &paths.dir).with_context(|| {
        format!("rename {} -> {}", target.display(), paths.dir.display())
    })?;

    if other.exists() {
        fs::remove_dir_all(other)
            .with_context(|| format!("remove {}", other.display()))?;
    }

    Ok(RecoverOutcome::Recovered)
}

/// Pick the newer of the two by mtime, falling back to `backup`.
///
/// An empty or missing `back_ovfs` never wins: it can be an artifact
/// of a startup that never got to resync, and picking it would lose
/// the real profile.
fn pick_recovery_target<'a>(
    backup: &'a Path,
    back_ovfs: &'a Path,
) -> &'a Path {
    if !back_ovfs.is_dir() || is_empty_dir(back_ovfs) {
        return backup;
    }
    match (mtime(backup), mtime(back_ovfs)) {
        // Ties go to `back_ovfs`: equal mtimes are timestamp-granularity
        // noise, and the mirror is never stale relative to its source.
        (Some(b), Some(o)) if o >= b => back_ovfs,
        _ => backup,
    }
}

fn mtime(p: &Path) -> Option<SystemTime> {
    fs::metadata(p).and_then(|m| m.modified()).ok()
}

/// Unreadable counts as empty, so the picker falls back to `backup`.
fn is_empty_dir(p: &Path) -> bool {
    fs::read_dir(p).map_or(true, |mut it| it.next().is_none())
}

#[cfg(test)]
mod tests {
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
        std::assert_matches!(recover(&paths).unwrap(), RecoverOutcome::Already);
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
        std::assert_matches!(recover(&paths).unwrap(), RecoverOutcome::Recovered);
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
        std::assert_matches!(recover(&paths).unwrap(), RecoverOutcome::Recovered);
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
        std::assert_matches!(recover(&paths).unwrap(), RecoverOutcome::Already);
        assert!(paths.dir.symlink_metadata().is_err());
    }
}
