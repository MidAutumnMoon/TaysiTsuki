use std::path::Path;
use std::path::PathBuf;
use std::process::Command;
use std::process::Stdio;

use gix_discover::repository;
use rootcause::Result;
use rootcause::prelude::ResultExt as _;
use rootcause::report;
use serde::de::DeserializeOwned;

/// Locate the repo root, like `git rev-parse --show-toplevel`.
pub fn repo_root() -> Result<PathBuf> {
    let cwd = std::env::current_dir().context("get cwd")?;
    // Trust level is irrelevant here, only the path is used.
    let (path, _) = gix_discover::upwards(&cwd)
        .map_err(gix_error::Exn::into_chain)
        .context("locate git repo toplevel")?;
    match path {
        repository::Path::WorkTree(path) => Ok(path),
        repository::Path::LinkedWorkTree { .. }
        | repository::Path::Repository(_) => {
            Err(report!("other types of repo are not handled"))
        }
    }
}

/// Resolve the __pin directory: absolute paths win, relative ones are
/// taken against the repo root (so the tool works from any subdir).
pub fn pin_dir(dir: &Path) -> Result<PathBuf> {
    if dir.is_absolute() {
        Ok(dir.to_path_buf())
    } else {
        Ok(repo_root()?.join(dir))
    }
}

/// Run a command with progress on stderr and no stdout. Driver stdout is
/// reserved for the refresh report consumed by CI.
pub fn run_checked(cmd: &mut Command, what: &str) -> Result<()> {
    let status = cmd
        .stdout(Stdio::null())
        .stderr(Stdio::inherit())
        .status()
        .context(format!("spawn: {what}"))?;
    if !status.success() {
        return Err(report!(format!("{what} failed ({status})")).into());
    }
    Ok(())
}

/// Evaluate one flake attribute as JSON and deserialize its public shape.
pub fn eval_json<T>(flake: &Path, attr: &str, what: &str) -> Result<T>
where
    T: DeserializeOwned,
{
    let output = Command::new("nix")
        .arg("eval")
        .arg("--json")
        .arg(format!("{}#{attr}", flake.display()))
        .output()
        .context(format!("spawn: {what}"))?;
    if !output.status.success() {
        return Err(report!(format!(
            "{what} failed ({}):\n{}",
            output.status,
            String::from_utf8_lossy(&output.stderr).trim(),
        ))
        .into());
    }
    Ok(serde_json::from_slice(&output.stdout)
        .context(format!("{what}: parse eval output"))?)
}
