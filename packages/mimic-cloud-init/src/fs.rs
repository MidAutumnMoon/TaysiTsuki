use std::fs::read_to_string;
use std::path::Path;
use std::process::Command;

use anyhow::Context as _;
use anyhow::Result as AnyResult;
use tap::Pipe as _;
use tempfile::TempDir;

pub struct MountAndRead {
    mountpoint: TempDir,
}

impl MountAndRead {
    pub fn new(drive: &Path) -> AnyResult<Self> {
        eprintln!("mount drive");
        let temp = TempDir::new()
            .context("Failed to create tempdir as mountpoint")?;
        temp.path();
        Command::new("mount")
            .arg(drive)
            .arg(temp.path())
            .spawn()
            .context("Failed to run mount command")?
            .wait()
            .context("mount error, read dmesg for diagnostics")?;
        Ok(Self { mountpoint: temp })
    }

    pub fn read_file(&self, path: &str) -> AnyResult<String> {
        &path;
        let full_path = self.mountpoint.path().join(path);
        &full_path;
        read_to_string(&full_path)
            .context("Failed to read file")?
            .pipe(Ok)
    }
}

impl Drop for MountAndRead {
    fn drop(&mut self) {
        eprintln!("attempt to unmount drive");
        Command::new("umount")
            .arg(self.mountpoint.path())
            .spawn()
            .expect("Failed to run unmount")
            .wait()
            .expect("umount error, read dmesg for diagnostics");
    }
}
