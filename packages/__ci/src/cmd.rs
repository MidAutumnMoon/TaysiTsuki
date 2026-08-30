use std::path::PathBuf;

use anyhow::Context as _;
use anyhow::Result;
use anyhow::bail;
use gix_discover::repository;
use tracing::debug;
use tracing::instrument;

#[instrument]
pub fn git_toplevel() -> Result<PathBuf> {
    debug!("Get git repository toplevel");
    let cwd = std::env::current_dir()?;
    // trust discarded
    let (path, _) = gix_discover::upwards(&cwd)
        .context("Failed to locate git repo toplevel")?;
    match path {
        repository::Path::WorkTree(path) => Ok(path),
        _ => bail!("Other types of repo are not handled"),
    }
}
