//! Wrapper around the `fuse-overlayfs` and `fusermount3` binaries.

use std::path::Path;
use std::process::Command;

use anyhow::Context;
use anyhow::Result;
use anyhow::bail;
use tracing::debug;
use which::which;

use crate::exec;

/// Verify required external binaries are on PATH.
pub fn check_dependencies() -> Result<()> {
    for bin in [
        "rsync",
        "fuse-overlayfs",
        "fusermount3",
        "mountpoint",
        "pgrep",
    ] {
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
    exec::run(
        Command::new("fuse-overlayfs")
            .arg("-o")
            .arg(&opts)
            .arg(mountpoint),
    )
    .with_context(|| {
        format!("mounting overlay at {}", mountpoint.display())
    })?;
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
    exec::run(Command::new("fusermount3").arg("-u").arg(mountpoint))
        .with_context(|| format!("unmounting {}", mountpoint.display()))
}

pub fn is_mountpoint(p: &Path) -> Result<bool> {
    let out = exec::output(Command::new("mountpoint").arg("-q").arg(p))?;
    Ok(out.status.success())
}
