//! Wrapper around the `fuse-overlayfs` and `fusermount3` binaries.

use std::fs;
use std::io::ErrorKind;
use std::path::Path;
use std::process::Command;
use std::thread::sleep;
use std::time::Duration;
use std::time::Instant;

use anyhow::Context as _;
use anyhow::Result;
use anyhow::bail;
use tracing::debug;
use tracing::warn;
use which::which;

use crate::exec;

/// Kernel-visible state of the expected FUSE mount.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum MountState {
    /// No mount exists at the path.
    Unmounted,
    /// The mount exists and its userspace daemon is responding.
    Mounted,
    /// The kernel mount remains, but its FUSE daemon has exited.
    Disconnected,
}

/// Verify required external binaries are on PATH.
pub fn check_dependencies() -> Result<()> {
    for bin in [
        "rsync",
        "fuse-overlayfs",
        "fusermount3",
        "mountpoint",
        "pgrep",
        "systemd-run",
        "systemctl",
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
    let fuse_overlayfs = which("fuse-overlayfs")
        .context("locating fuse-overlayfs for transient service")?;
    let unit = format!(
        "psd-overlay-{}-{}.service",
        std::process::id(),
        std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .context("system clock is before the Unix epoch")?
            .as_nanos()
    );
    let mut command =
        transient_mount_command(&unit, &fuse_overlayfs, &opts, mountpoint);
    exec::run(&mut command).with_context(|| {
        format!(
            "starting transient overlay service {unit} for {}",
            mountpoint.display()
        )
    })?;

    let deadline = Instant::now() + Duration::from_secs(5);
    loop {
        match mount_state(mountpoint)? {
            MountState::Mounted => return Ok(()),
            MountState::Disconnected => {
                stop_transient_unit(&unit);
                bail!(
                    "overlay at {} disconnected immediately after mounting",
                    mountpoint.display()
                );
            }
            MountState::Unmounted if Instant::now() < deadline => {
                sleep(Duration::from_millis(20));
            }
            MountState::Unmounted => {
                stop_transient_unit(&unit);
                bail!(
                    "transient service {unit} did not mount {} within 5s",
                    mountpoint.display()
                );
            }
        }
    }
}

fn transient_mount_command(
    unit: &str,
    fuse_overlayfs: &Path,
    opts: &str,
    mountpoint: &Path,
) -> Command {
    let mut command = Command::new("systemd-run");
    command
        .args([
            "--user",
            "--quiet",
            "--collect",
            "--service-type=exec",
            "--expand-environment=no",
            // App shutdown must not kill the mount before persistence.
            "--slice=session.slice",
        ])
        .arg(format!("--unit={unit}"))
        .arg(format!(
            "--description=psd overlay at {}",
            mountpoint.display()
        ))
        .arg(fuse_overlayfs)
        .arg("-f")
        .arg("-o")
        .arg(opts)
        .arg(mountpoint);
    command
}

fn stop_transient_unit(unit: &str) {
    if let Err(error) =
        exec::run(Command::new("systemctl").args(["--user", "stop", unit]))
    {
        warn!(
            unit,
            error = %format_args!("{error:#}"),
            "failed to stop unsuccessful transient overlay service"
        );
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
    let state = mount_state(mountpoint)?;
    match (result, state) {
        (Ok(()), MountState::Unmounted) => Ok(()),
        (Ok(()), MountState::Mounted) => bail!(
            "unmount reported success but {} is still mounted",
            mountpoint.display()
        ),
        (Ok(()), MountState::Disconnected) => bail!(
            "unmount reported success but {} is still a disconnected mount",
            mountpoint.display()
        ),
        (Err(error), MountState::Mounted | MountState::Disconnected) => {
            Err(error)
        }
        (Err(error), MountState::Unmounted) => {
            warn!(
                mountpoint = %mountpoint.display(),
                error = %format_args!("{error:#}"),
                "unmount command failed after detaching the overlay; continuing"
            );
            Ok(())
        }
    }
}

pub fn mount_state(path: &Path) -> Result<MountState> {
    match runtime_entry_state(path)? {
        RuntimeEntryState::Missing => {
            debug!(
                path = %path.display(),
                "runtime mountpoint is absent; treating it as unmounted"
            );
            return Ok(MountState::Unmounted);
        }
        RuntimeEntryState::Disconnected => {
            warn!(
                path = %path.display(),
                "FUSE mount is disconnected from its userspace daemon"
            );
            return Ok(MountState::Disconnected);
        }
        RuntimeEntryState::Present => {}
    }

    // Keep command output so genuine failures have a diagnostic. `-q`
    // suppresses the useful error text for missing or inaccessible paths.
    let output = exec::output(Command::new("mountpoint").arg(path))
        .with_context(|| {
            format!("checking mount state for {}", path.display())
        })?;
    match output.status.code() {
        Some(0) => probe_connected_mount(path),
        // util-linux mountpoint(1): 32 means "not a mountpoint".
        Some(32) => {
            debug!(path = %path.display(), "runtime path is not mounted");
            Ok(MountState::Unmounted)
        }
        code => match runtime_entry_state(path)? {
            RuntimeEntryState::Missing => {
                debug!(
                    path = %path.display(),
                    exit = code.unwrap_or(-1),
                    "runtime mountpoint disappeared during inspection"
                );
                Ok(MountState::Unmounted)
            }
            RuntimeEntryState::Disconnected => {
                warn!(
                    path = %path.display(),
                    "FUSE mount disconnected during inspection"
                );
                Ok(MountState::Disconnected)
            }
            RuntimeEntryState::Present => {
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
        },
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
enum RuntimeEntryState {
    Missing,
    Present,
    Disconnected,
}

fn runtime_entry_state(path: &Path) -> Result<RuntimeEntryState> {
    match fs::symlink_metadata(path) {
        Ok(_) => Ok(RuntimeEntryState::Present),
        Err(error) if error.kind() == ErrorKind::NotFound => {
            Ok(RuntimeEntryState::Missing)
        }
        Err(error) if error.kind() == ErrorKind::NotConnected => {
            Ok(RuntimeEntryState::Disconnected)
        }
        Err(error) => Err(error).with_context(|| {
            format!("inspect runtime path {}", path.display())
        }),
    }
}

fn probe_connected_mount(path: &Path) -> Result<MountState> {
    let mut entries = match fs::read_dir(path) {
        Ok(entries) => entries,
        Err(error) if error.kind() == ErrorKind::NotConnected => {
            warn!(
                path = %path.display(),
                "FUSE mount exists but its userspace daemon is disconnected"
            );
            return Ok(MountState::Disconnected);
        }
        Err(error) => {
            return Err(error).with_context(|| {
                format!("probe mounted path {}", path.display())
            });
        }
    };
    match entries.next() {
        Some(Err(error)) if error.kind() == ErrorKind::NotConnected => {
            warn!(
                path = %path.display(),
                "FUSE mount disconnected while probing it"
            );
            Ok(MountState::Disconnected)
        }
        Some(Err(error)) => Err(error).with_context(|| {
            format!("read mounted path {}", path.display())
        }),
        Some(Ok(_)) | None => Ok(MountState::Mounted),
    }
}

#[cfg(test)]
#[expect(clippy::unwrap_used, reason = "Test")]
mod tests {
    use super::*;

    use tempfile::tempdir;

    #[test]
    fn absent_runtime_path_is_unmounted() {
        let temp = tempdir().unwrap();
        assert_eq!(
            mount_state(&temp.path().join("missing")).unwrap(),
            MountState::Unmounted
        );
    }

    #[test]
    fn transient_overlay_runs_outside_app_slice() {
        let command = transient_mount_command(
            "psd-overlay-test.service",
            Path::new("/bin/fuse-overlayfs"),
            "lowerdir=/lower,upperdir=/upper,workdir=/work",
            Path::new("/run/user/1000/psd/profile"),
        );

        assert!(
            command
                .get_args()
                .any(|argument| argument == "--slice=session.slice")
        );
    }
}
