//! Ungraceful state normalization.
//!
//! After a crash, `DIR` is a dangling symlink (tmpfs gone) while `BACKUP`
//! still exists on disk. This makes remounting impossible, so we must
//! normalize before startup.
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
use anyhow::bail;
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

    // DIR is a symlink. If it resolves, the session is still live -- refuse
    // to touch it.
    if paths.dir.is_symlink() && paths.dir.exists() {
        bail!(
            "{} is a symlink to an existing path; refusing to recover a live session",
            paths.dir.display()
        );
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
