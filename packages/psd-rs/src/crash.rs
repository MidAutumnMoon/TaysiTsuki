//! Ungraceful state normalization.
//!
//! ## psd v7 behavior
//!
//! On every startup, `ungraceful_state_check` looks at each profile. If
//! `DIR/.flagged` is missing (it always is after a reboot, since it lives
//! in the tmpfs overlay), it assumes a crash and:
//!
//! 1. `unlink $DIR` (dangling symlink, since tmpfs is gone)
//! 2. Pick newer of `BACKUP` / `BACK_OVFS` by mtime
//! 3. Optionally `cp -a` that to `BACKUP-crashrecovery-<ts>` (the snapshot)
//! 4. `mv $picked $DIR`, `rm -rf $other`
//!
//! ## Why psd drops the snapshot step
//!
//! The snapshot doesn't protect against the likely failure modes:
//!
//! - Picked the wrong target? Snapshot is of the wrong pick. Doesn't help.
//! - Recovery bug (e.g. an empty `BACK_OVFS` picked over `BACKUP`)?
//!   Snapshot might be of an empty dir. Doesn't help.
//! - Browser corrupts the profile after launch? This is just a backup,
//!   which restic already provides -- redundant.
//!
//! The snapshot was also the most expensive part of psd v7: a `cp -a` of
//! the full profile (2GB+) per recovery, capped at 5 copies = 12GB of
//! disk. With restic backing up `~/.mozilla`, this is pure overhead.
//!
//! ## What psd keeps
//!
//! State normalization is mandatory for correctness: a dangling `DIR`
//! plus existing `BACKUP` makes the overlay mount impossible. The logic:
//!
//! 1. Detect dangling `DIR` (symlink to missing tmpfs) or missing `DIR`
//! 2. Pick the newer of `BACKUP` / `BACK_OVFS` (rejecting empty `BACK_OVFS`)
//! 3. Rename the picked target to `DIR`
//! 4. Delete the other
//!
//! Maximum data loss is one resync interval (default 30min).

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
/// "Ungraceful" = `DIR` is a dangling symlink (tmpfs gone) while `BACKUP`
/// exists on disk. If `DIR` is a real directory (non-symlink), the previous
/// session was clean (or psd never ran) and we skip.
///
/// Returns `true` if recovery was performed.
pub fn recover(paths: &ProfilePaths) -> Result<bool> {
    // Clean session marker: a real (non-symlink) DIR means unsync
    // completed, or psd never ran. Either way, nothing to recover.
    if paths.dir.is_dir() && !paths.dir.is_symlink() {
        return Ok(false);
    }

    // DIR is a symlink. If it resolves, the session is still live -- refuse
    // to touch it (psd v7 would `exit 1` here; we do the same).
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
            // the browser recreates the profile from scratch on next launch.
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
