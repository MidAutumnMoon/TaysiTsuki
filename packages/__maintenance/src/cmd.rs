use std::ffi::OsStr;
use std::path::PathBuf;
use std::process::Command;

use anyhow::Context;
use anyhow::Result;
use anyhow::bail;
use tap::Pipe;
use tracing::debug;
use tracing::instrument;

#[instrument(skip(args))]
pub fn capture_cmd_output<A>(cmd: &str, args: &[&A]) -> Result<String>
where
    A: AsRef<OsStr> + ?Sized,
{
    debug!("Capture command output");

    let ret = Command::new(cmd)
        .args(args)
        .output()
        .with_context(|| format!("Failed to run command {cmd}"))?;

    if !ret.status.success() {
        debug!("Command exited with error");
        let stderr = ret.stderr.pipe_as_ref(String::from_utf8_lossy);
        eprintln!("{stderr}");
        bail!("Command {cmd} failed");
    }

    ret.stdout
        .pipe(String::from_utf8)
        .context("Command output isn't valid UTF-8")
        .pipe(|v| v.map(|s| s.trim().into()))
}

#[instrument]
pub fn git_toplevel() -> Result<PathBuf> {
    debug!("Get git repository toplevel");
    let cwd = std::env::current_dir()?;
    // trust discarded
    let (path, _) = gix_discover::upwards(&cwd)
        .context("Failed to locate git repo toplevel")?;
    match path {
        gix_discover::repository::Path::WorkTree(p) => Ok(p),
        _ => bail!("Other types of repo are not handled"),
    }
}
