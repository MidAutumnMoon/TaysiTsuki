//! Path resolution for a managed app profile.
//!
//! The 5-path model:
//!
//! - `DIR` - what the app sees
//! - `BACKUP` - frozen profile, renamed from `DIR` at startup;
//!   overlay lowerdir (read-only while mounted)
//! - `BACK_OVFS` - on-disk staging dir, writable while overlay is live;
//!   receives periodic resyncs; merged into `BACKUP` at unsync
//! - `TMP` - overlay mount point in tmpfs; `DIR` symlinks here
//! - `UPPER` - tmpfs dir holding overlay writes (the delta)
//! - `WORK` - overlay internal workdir
//!
//! Why `BACK_OVFS` exists: `BACKUP` is the overlay lowerdir, so writing
//! to it while mounted is unsafe (cached inode listings desync from
//! disk). `BACK_OVFS` sits outside the overlay, safe to write at any
//! time. It also bounds crash-loss to <=1 resync interval and gives the
//! final unsync merge a stable intermediate target.

use std::path::Path;
use std::path::PathBuf;

use crate::apps::AppProfile;

#[derive(Debug, Clone)]
pub struct ProfilePaths {
    /// What the app reads/writes. Symlink to `tmp` when active.
    pub dir: PathBuf,
    /// Frozen original profile; overlay lowerdir while active.
    pub backup: PathBuf,
    /// Writable on-disk staging for resyncs; merged into `backup` at unsync.
    pub back_ovfs: PathBuf,
    /// Overlay mount point in tmpfs; `dir` symlinks here.
    pub tmp: PathBuf,
    /// Overlay upperdir in tmpfs (the delta).
    pub upper: PathBuf,
    /// Overlay workdir in tmpfs.
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
        // WORK gets a dot prefix: fuse-overlayfs requires it to be empty,
        // and the dot keeps it out of the way.
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
}

/// Append a string suffix to a path's final component.
pub fn append_suffix(p: &Path, suffix: &str) -> PathBuf {
    let mut s = p.as_os_str().to_owned();
    s.push(suffix);
    PathBuf::from(s)
}
