//! Path resolution for a managed app profile.
//!
//! - `DIR` - what the app sees; symlink to `TMP` while the session
//!   is live
//! - `BACKUP` - frozen original profile; the overlay's lowerdir
//! - `BACK_OVFS` - writable on-disk mirror of the overlay view
//! - `TMP` - overlay mountpoint in tmpfs
//! - `UPPER`, `WORK` - overlay upper/work dirs in tmpfs (the delta)
//!
//! `BACK_OVFS` exists because the lowerdir must not be written while
//! its overlay is mounted. Kept outside the overlay, it is safe to
//! update at any time, bounds crash loss to one resync interval, and
//! unsync promotes it to `DIR` with a rename.

use std::path::Path;
use std::path::PathBuf;

use crate::apps::AppProfile;

#[derive(Debug, Clone)]
pub struct ProfilePaths {
    /// What the app sees; symlink to `tmp` while the session is live.
    pub dir: PathBuf,
    /// Frozen original profile; the overlay's lowerdir while live.
    pub backup: PathBuf,
    /// On-disk mirror of the overlay view; promoted to `dir` at unsync.
    pub back_ovfs: PathBuf,
    /// Overlay mountpoint in tmpfs.
    pub tmp: PathBuf,
    /// Overlay writes (the session delta) in tmpfs.
    pub upper: PathBuf,
    /// Overlay-internal workdir in tmpfs.
    pub work: PathBuf,
}

impl ProfilePaths {
    /// Resolve all paths for one profile.
    pub fn new(profile: &AppProfile, volatile_root: &Path) -> Self {
        let dir = profile.path.clone();
        let backup = append_suffix(&dir, "-backup");
        let back_ovfs = append_suffix(&dir, "-back-ovfs");

        let tag = format!(
            "{}-{}-{}",
            profile.user,
            profile.kind.as_ref(),
            profile.suffix
        );
        let tmp = volatile_root.join(&tag);
        let upper = volatile_root.join(format!("{tag}-rw"));
        // Dot prefix keeps the internal workdir out of sight.
        let work = volatile_root.join(format!(".{tag}"));

        Self {
            dir,
            backup,
            back_ovfs,
            tmp,
            upper,
            work,
        }
    }

    /// True when `DIR` resolves to an existing path (the session looks
    /// live). Does not verify the overlay is still mounted -- see
    /// [`crate::sync::overlay_live`].
    pub fn is_live(&self) -> bool {
        self.dir.is_symlink() && self.dir.exists()
    }
}

/// Append a string suffix to a path's final component.
pub fn append_suffix(p: &Path, suffix: &str) -> PathBuf {
    let mut s = p.as_os_str().to_owned();
    s.push(suffix);
    PathBuf::from(s)
}
