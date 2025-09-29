// Use noah once it is finished

use std::process::Command;

use anyhow::Context;
use anyhow::Result;
use anyhow::bail;
use anyhow::ensure;
use indoc::formatdoc;
use tap::Pipe;
use tracing::debug;

use crate::package::NIX_BUILD_OPTS;

// TODO: dedup the command pattern
pub fn eval_hostnames() -> Result<String> {
    let toplevel = git_toplevel()?;
    let driver = formatdoc! {r#"
        with builtins;
        let flake = getFlake (toString {toplevel}); in
        assert hasAttr "nixosConfigurations" flake;
        attrNames flake.nixosConfigurations
    "#};
    let output = Command::new("nix")
        .arg("eval")
        .arg("--impure")
        .arg("--json")
        .args(["--expr", &driver])
        .output()
        .context("Failed to run nix command")?;
    if !output.status.success() {
        debug!("Nix command error");
        eprintln!(
            "Nix command stderr: {}",
            output.stderr.pipe_as_ref(String::from_utf8_lossy)
        );
        bail!("Nix command error")
    }
    output
        .stdout
        .pipe(String::from_utf8)
        .context("Nix output isn't valid UTF-8")
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

fn git_toplevel() -> Result<String> {
    let output = Command::new("git")
        .arg("rev-parse")
        .arg("--show-toplevel")
        .output()
        .context("Failed to run git command")?;
    if !output.status.success() {
        eprintln!(
            "Git stderr: {}",
            output.stderr.pipe_as_ref(String::from_utf8_lossy)
        );
        bail!("git command failed");
    }
    output
        .stdout
        .pipe(String::from_utf8)
        .context("Git output isn't valid UTF-8")
}
