//! Wrapper around the `fuse-overlayfs` and `fusermount3` binaries.

use std::path::Path;
use std::process::Command;

use anyhow::Context;
use anyhow::Result;
use anyhow::bail;
use tracing::debug;
use which::which;

/// Verify required external binaries are on PATH.
pub fn check_dependencies() -> Result<()> {
    for bin in ["rsync", "fuse-overlayfs", "fusermount3", "mountpoint"] {
        which(bin).with_context(|| {
            format!("required binary `{bin}` not found on PATH")
        })?;
    }
    Ok(())
}

/// Mount an overlay at `mountpoint` with `lowerdir`/`upperdir`/`workdir`.
pub fn mount(
    lower: &Path,
    upper: &Path,
    work: &Path,
    mountpoint: &Path,
) -> Result<()> {
    let opts = format!(
        "lowerdir={},upperdir={},workdir={}",
        lower.display(),
        upper.display(),
        work.display()
    );
    debug!(opts = %opts, mountpoint = %mountpoint.display(), "mounting overlay");
    let status = Command::new("fuse-overlayfs")
        .arg("-o")
        .arg(&opts)
        .arg(mountpoint)
        .status()
        .context("spawning fuse-overlayfs")?;
    if !status.success() {
        bail!(
            "fuse-overlayfs mount failed (exit {})",
            status.code().unwrap_or(-1)
        );
    }
    if !is_mountpoint(mountpoint)? {
        bail!(
            "mount reported success but {} is not a mountpoint",
            mountpoint.display()
        );
    }
    Ok(())
}

/// Unmount a FUSE mount.
pub fn unmount(mountpoint: &Path) -> Result<()> {
    let status = Command::new("fusermount3")
        .arg("-u")
        .arg(mountpoint)
        .status()
        .context("spawning fusermount3")?;
    if !status.success() {
        bail!(
            "fusermount3 -u failed (exit {})",
            status.code().unwrap_or(-1)
        );
    }
    Ok(())
}

pub fn is_mountpoint(p: &Path) -> Result<bool> {
    let status = Command::new("mountpoint")
        .arg("-q")
        .arg(p)
        .status()
        .context("spawning mountpoint")?;
    Ok(status.success())
}
