use std::process::Command;
use std::process::Output;
use std::sync::mpsc::sync_channel;

use anyhow::Context;
use anyhow::Result;
use anyhow::bail;
use anyhow::ensure;
use tracing::debug;
use tracing::instrument;
use tracing::warn;

use crate::manifest::Package;

#[rustfmt::skip]
pub static NIX_BUILD_OPTS: &[&str] = &[
    "--no-link",
    "--print-build-logs",
    "--keep-failed",
    "--option", "narinfo-cache-negative-ttl", "0",
    "--option", "keep-going", "true",
    "--option", "max-jobs", "1",
];

#[instrument(skip_all)]
pub fn build_packages<'a>(
    packages: impl IntoIterator<Item = &'a Package>,
) -> Result<()> {
    debug!("Build packages");

    let attrs = packages
        .into_iter()
        .map(|p| format!(".#{}", &p.attr))
        .collect::<Vec<_>>();

    if attrs.is_empty() {
        bail!("No package selected to build");
    }

    debug!(?attrs, "Attrs for nix to build");

    let status = Command::new("nix")
        .arg("build")
        .args(NIX_BUILD_OPTS)
        .args(attrs)
        .spawn()
        .context("Failed to spawn nix build command")?
        .wait()
        .context("Failed waiting nix build child process")?;

    ensure!(status.success(), "Nix build failed");
    Ok(())
}

#[instrument(skip_all)]
pub fn update_packages<'a>(
    packages: impl IntoIterator<Item = &'a Package>,
) -> Result<()> {
    todo!()
}
