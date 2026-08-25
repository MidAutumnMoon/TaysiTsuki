//! Path resolution for a managed app profile.
//!
//! - `DIR` - what the app sees; symlink to `TMP` while live
//! - `BACKUP` - frozen original profile; the overlay lowerdir
//! - `BACK_OVFS` - last complete on-disk checkpoint
//! - `BACK_OVFS_STAGE` - incomplete checkpoint under construction
//! - `TMP` - overlay mountpoint in tmpfs
//! - `UPPER`, `WORK` - overlay upper/work dirs in tmpfs
//!
//! The frozen lowerdir is never modified while mounted. Checkpoints are built
//! beside `BACK_OVFS` and atomically exchanged only after completion.

use std::fmt;
use std::fs;
use std::io::ErrorKind;
use std::path::Path;
use std::path::PathBuf;

use anyhow::Context as _;
use anyhow::Result;
use anyhow::bail;
use tracing::debug;

use crate::apps::AppProfile;
use crate::overlay;
use crate::overlay::MountState;

#[derive(Debug, Clone)]
pub struct ProfilePaths {
    /// What the app sees; symlink to `tmp` while the session is live.
    pub dir: PathBuf,
    /// Frozen original profile; the overlay's lowerdir while live.
    pub backup: PathBuf,
    /// Last atomically committed on-disk mirror of the overlay view.
    pub back_ovfs: PathBuf,
    /// Fresh checkpoint under construction; never a recovery source.
    pub back_ovfs_stage: PathBuf,
    /// Sidecar marker written by the previous checkpoint format.
    pub legacy_back_ovfs_committed: PathBuf,
    /// Overlay mountpoint in tmpfs.
    pub tmp: PathBuf,
    /// Overlay writes (the session delta) in tmpfs.
    pub upper: PathBuf,
    /// Overlay-internal workdir in tmpfs.
    pub work: PathBuf,
}

/// Relationship between the app-visible path and its expected overlay.
///
/// Unexpected filesystem entries are errors rather than states: psd must
/// never replace a path it cannot prove it owns.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum SessionState {
    /// `DIR` is an ordinary on-disk profile directory.
    PlainDirectory,
    /// `DIR` does not exist and no overlay is mounted.
    Missing,
    /// `DIR` points to the mounted overlay.
    Live,
    /// `DIR` points to `TMP`, but `TMP` is no longer mounted.
    StaleSymlink,
    /// `TMP` is mounted, but the managed `DIR` symlink is missing.
    OrphanMount,
    /// The kernel mount remains, but its FUSE daemon has exited.
    DisconnectedMount,
}

impl fmt::Display for SessionState {
    fn fmt(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        formatter.write_str(match self {
            Self::PlainDirectory => "plain",
            Self::Missing => "missing",
            Self::Live => "live",
            Self::StaleSymlink => "stale-symlink",
            Self::OrphanMount => "orphan-mount",
            Self::DisconnectedMount => "disconnected",
        })
    }
}

impl ProfilePaths {
    /// Resolve all paths for one profile.
    pub fn new(profile: &AppProfile, volatile_root: &Path) -> Self {
        let dir = profile.path.clone();
        let backup = append_suffix(&dir, "-backup");
        let back_ovfs = append_suffix(&dir, "-back-ovfs");
        let back_ovfs_stage = append_suffix(&dir, "-back-ovfs-staging");
        let legacy_back_ovfs_committed =
            append_suffix(&dir, "-back-ovfs-committed");

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
            back_ovfs_stage,
            legacy_back_ovfs_committed,
            tmp,
            upper,
            work,
        }
    }

    /// Classify the complete session state, including the actual mount.
    pub fn session_state(&self) -> Result<SessionState> {
        let mount_state =
            overlay::mount_state(&self.tmp).with_context(|| {
                format!(
                    "inspect overlay mount {} for profile {}",
                    self.tmp.display(),
                    self.dir.display()
                )
            })?;
        let state = self.classify_session(mount_state)?;
        debug!(
            dir = %self.dir.display(),
            tmp = %self.tmp.display(),
            ?mount_state,
            state = %state,
            "classified profile session"
        );
        Ok(state)
    }

    /// Classify `DIR` against an already-observed mount state.
    ///
    /// Kept separate so recovery tests can exercise crash windows without
    /// creating real FUSE mounts.
    pub(crate) fn classify_session(
        &self,
        mount_state: MountState,
    ) -> Result<SessionState> {
        let metadata = match fs::symlink_metadata(&self.dir) {
            Ok(metadata) => Some(metadata),
            Err(error) if error.kind() == ErrorKind::NotFound => None,
            Err(error) => {
                return Err(error).with_context(|| {
                    format!("inspect {}", self.dir.display())
                });
            }
        };

        let Some(metadata) = metadata else {
            return Ok(match mount_state {
                MountState::Unmounted => SessionState::Missing,
                MountState::Mounted => SessionState::OrphanMount,
                MountState::Disconnected => {
                    SessionState::DisconnectedMount
                }
            });
        };

        if metadata.file_type().is_symlink() {
            let target = fs::read_link(&self.dir).with_context(|| {
                format!("read symlink {}", self.dir.display())
            })?;
            if target != self.tmp {
                bail!(
                    "{} points to {}, not psd's expected {}; refusing to \
                     modify it",
                    self.dir.display(),
                    target.display(),
                    self.tmp.display()
                );
            }
            return Ok(match mount_state {
                MountState::Unmounted => SessionState::StaleSymlink,
                MountState::Mounted => SessionState::Live,
                MountState::Disconnected => {
                    SessionState::DisconnectedMount
                }
            });
        }

        if !metadata.is_dir() {
            bail!(
                "{} is neither a directory nor psd's managed symlink",
                self.dir.display()
            );
        }
        match mount_state {
            MountState::Unmounted => Ok(SessionState::PlainDirectory),
            MountState::Mounted => {
                bail!(
                    "{} is mounted while {} is a plain directory; refusing to \
                     guess which contains current data",
                    self.tmp.display(),
                    self.dir.display()
                );
            }
            MountState::Disconnected => {
                bail!(
                    "{} is a disconnected mount while {} is a plain \
                     directory; refusing automatic recovery",
                    self.tmp.display(),
                    self.dir.display()
                );
            }
        }
    }
}

/// Append a string suffix to a path's final component.
pub fn append_suffix(path: &Path, suffix: &str) -> PathBuf {
    let mut path = path.as_os_str().to_owned();
    path.push(suffix);
    PathBuf::from(path)
}
