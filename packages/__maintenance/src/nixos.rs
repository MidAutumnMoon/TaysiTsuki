// Use noah once it is finished

use std::process::Command;

use anyhow::Context;
use anyhow::Result;
use anyhow::bail;
use anyhow::ensure;
use indoc::formatdoc;
use tap::Pipe;
use tracing::debug;

use crate::cmd::capture_cmd_output;
use crate::package::NIX_BUILD_OPTS;

// TODO: dedup the command pattern
pub fn eval_hostnames() -> Result<String> {
    let toplevel =
        capture_cmd_output("git", &["rev-parse", "--show-toplevel"])?;
    let driver = formatdoc! {r#"
        with builtins;
        let flake = getFlake (toString {toplevel}); in
        assert hasAttr "nixosConfigurations" flake;
        attrNames flake.nixosConfigurations
    "#};
    capture_cmd_output(
        "nix",
        &["eval", "--impure", "--json", "--expr", &driver],
    )
}

pub fn build_nixos(hostname: &str) -> Result<()> {
    let attr = format!(
        ".#nixosConfigurations.{hostname}.config.system.build.toplevel"
    );
    debug!(?attr, "Attrs for nix to build");

    let status = Command::new("nix")
        .arg("build")
        .args(NIX_BUILD_OPTS)
        .arg(attr)
        .spawn()
        .context("Failed to spawn nix build command")?
        .wait()
        .context("Failed waiting nix build child process")?;

    ensure!(status.success(), "Nix build failed");
    Ok(())
}
