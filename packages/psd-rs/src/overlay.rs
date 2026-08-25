//! Wrapper around the `fuse-overlayfs` and `fusermount3` binaries.

use std::fs;
use std::io::ErrorKind;
use std::path::Path;
use std::process::Command;

use anyhow::Context as _;
use anyhow::Result;
use anyhow::bail;
use tracing::debug;
use tracing::warn;
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
    let result = exec::run(
        Command::new("fuse-overlayfs")
            .arg("-o")
            .arg(&opts)
            .arg(mountpoint),
    )
    .with_context(|| {
        format!("mounting overlay at {}", mountpoint.display())
    });
    let mounted = is_mountpoint(mountpoint)?;
    match (result, mounted) {
        (Ok(()), true) => Ok(()),
        (Ok(()), false) => bail!(
            "mount reported success but {} is not a mountpoint",
            mountpoint.display()
        ),
        (Err(error), _) => Err(error),
    }
}

/// Unmount a FUSE mount and verify the resulting mount state.
///
/// `fusermount3` can report failure after detaching the mount. The
/// postcondition is authoritative: once detached, teardown must continue
/// instead of leaving a resolving stale symlink behind.
pub fn unmount(mountpoint: &Path) -> Result<()> {
    let result =
        exec::run(Command::new("fusermount3").arg("-u").arg(mountpoint))
            .with_context(|| {
                format!("unmounting {}", mountpoint.display())
            });
    let mounted = is_mountpoint(mountpoint)?;
    match (result, mounted) {
        (Ok(()), false) => Ok(()),
        (Ok(()), true) => bail!(
            "unmount reported success but {} is still mounted",
            mountpoint.display()
        ),
        (Err(error), true) => Err(error),
        (Err(error), false) => {
            warn!(
                mountpoint = %mountpoint.display(),
                error = %format_args!("{error:#}"),
                "unmount command failed after detaching the overlay; continuing"
            );
            Ok(())
        }
    }
}

pub fn is_mountpoint(path: &Path) -> Result<bool> {
    if !entry_exists(path)? {
        debug!(
            path = %path.display(),
            "runtime mountpoint is absent; treating it as unmounted"
        );
        return Ok(false);
    }

    // Keep command output so genuine failures have a diagnostic. `-q`
    // suppresses the useful error text for missing or inaccessible paths.
    let output = exec::output(Command::new("mountpoint").arg(path))
        .with_context(|| {
            format!("checking mount state for {}", path.display())
        })?;
    match output.status.code() {
        Some(0) => Ok(true),
        // util-linux mountpoint(1): 32 means "not a mountpoint".
        Some(32) => {
            debug!(path = %path.display(), "runtime path is not mounted");
            Ok(false)
        }
        code if !entry_exists(path)? => {
            // The runtime directory can disappear between the metadata check
            // and mountpoint(1), especially while a FUSE daemon is exiting.
            debug!(
                path = %path.display(),
                exit = code.unwrap_or(-1),
                "runtime mountpoint disappeared during inspection"
            );
            Ok(false)
        }
        code => {
            let stderr = String::from_utf8_lossy(&output.stderr);
            let stdout = String::from_utf8_lossy(&output.stdout);
            let diagnostic = stderr.trim();
            let diagnostic = if diagnostic.is_empty() {
                stdout.trim()
            } else {
                diagnostic
            };
            let diagnostic = if diagnostic.is_empty() {
                "no diagnostic output"
            } else {
                diagnostic
            };
            bail!(
                "could not determine whether {} is mounted: `mountpoint` \
                 exited {} ({diagnostic})",
                path.display(),
                code.unwrap_or(-1)
            );
        }
    }
}

fn entry_exists(path: &Path) -> Result<bool> {
    match fs::symlink_metadata(path) {
        Ok(_) => Ok(true),
        Err(error) if error.kind() == ErrorKind::NotFound => Ok(false),
        Err(error) => Err(error).with_context(|| {
            format!("inspect runtime path {}", path.display())
        }),
    }
}

#[cfg(test)]
#[expect(clippy::unwrap_used, reason = "Test")]
mod tests {
    use super::*;

    use tempfile::tempdir;

    #[test]
    fn absent_runtime_path_is_not_a_mountpoint() {
        let temp = tempdir().unwrap();
        assert!(!is_mountpoint(&temp.path().join("missing")).unwrap());
    }
}
