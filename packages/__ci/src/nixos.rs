// Use noah once it is finished

use std::process::Command;

use anyhow::Context as _;
use anyhow::Result;
use anyhow::ensure;
use docstr::docstr;
use ino_shell::Shell;
use ino_shell::cmd;
use tracing::debug;

use crate::cmd::git_toplevel;
use crate::package::NIX_BUILD_OPTS;

pub fn eval_hostnames() -> Result<String> {
    let toplevel = git_toplevel()?;
    let toplevel = toplevel
        .as_os_str()
        .to_str()
        .context("Git toplevel path is not valid UTF-8")?;
    let driver = docstr!(format!
        /// with builtins;
        /// let flake = getFlake (toString {toplevel}); in
        /// assert hasAttr "nixosConfigurations" flake;
        /// attrNames flake.nixosConfigurations
    );
    let sh = Shell::new()?;
    Ok(cmd!(sh, "nix eval --impure --json --expr {driver}").read()?)
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
