//! Path resolution for a managed browser profile.
//!
//! Mirrors the 5-path model from psd v7:
//!
//! - `DIR` - what the browser sees (`~/.mozilla/firefox/<profile>`)
//! - `BACKUP` - frozen profile, renamed from `DIR` at startup;
//!   becomes the overlay lowerdir (read-only while mounted)
//! - `BACK_OVFS` - on-disk staging dir, writable while overlay is live;
//!   receives periodic resyncs; merged into `BACKUP` at unsync
//! - `TMP` - overlay mount point in tmpfs (`$XDG_RUNTIME_DIR/psd/...`);
//!   `DIR` symlinks here
//! - `UPPER` - tmpfs dir holding overlay writes (the delta)
//! - `WORK` - overlay internal workdir
//!
//! Why `BACK_OVFS` exists (not in v6 psd):
//! `BACKUP` is the overlay lowerdir; writing to it while the overlay is
//! mounted is unsafe (cached inode listings desync from disk). `BACK_OVFS`
//! sits outside the overlay so it's safe to write at any time. It also
//! bounds crash-loss to ≤1 resync interval and gives the final unsync
//! merge a stable intermediate target.

use std::path::Path;
use std::path::PathBuf;

use crate::browser::BrowserProfile;

#[derive(Debug, Clone)]
pub struct ProfilePaths {
    /// What the browser reads/writes. Symlink to `tmp` when active.
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
    ///
    /// `volatile_root` is `$XDG_RUNTIME_DIR/psd` (tmpfs).
    /// `suffix` disambiguates multiple profiles per browser (e.g. firefox
    /// profile dirs); empty for single-profile browsers.
    pub fn new(
        profile: &BrowserProfile,
        volatile_root: &Path,
        suffix: &str,
    ) -> Self {
        let dir = profile.path.clone();
        let backup = append_suffix(&dir, "-backup");
        let back_ovfs = append_suffix(&dir, "-back-ovfs");

        let tag = format!(
            "{}-{name}{suffix}",
            profile.user,
            name = profile.kind.as_ref()
        );
        let tmp = volatile_root.join(&tag);
        let upper = volatile_root.join(format!("{tag}-rw"));
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
/// Used for `DIR` -> `BACKUP`/`BACK_OVFS` naming.
pub fn append_suffix(p: &Path, suffix: &str) -> PathBuf {
    let mut s = p.as_os_str().to_owned();
    s.push(suffix);
    PathBuf::from(s)
}
