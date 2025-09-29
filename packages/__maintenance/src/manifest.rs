use std::path::Path;
use std::process::Command;
use std::str::FromStr;

use anyhow::Context;
use anyhow::Result;
use anyhow::bail;
use serde::Deserialize;
use tap::Pipe;
use tap::Tap;
use tracing::debug;
use tracing::instrument;

#[derive(Debug)]
pub struct Manifest {
    packages: Vec<Package>,
}

impl FromStr for Manifest {
    type Err = anyhow::Error;
    fn from_str(input: &str) -> Result<Self, Self::Err> {
        let packages = serde_json::from_str(input)
            .context("Failed to parse manifest")?;
        Ok(Self { packages })
    }
}

impl Manifest {
    /// Eval a nix file and convert the output JSON into manifest.
    #[instrument]
    pub fn from_eval_nix(nix_file: &Path) -> Result<Self> {
        debug!("Try to eval nix file");
        let output = Command::new("nix")
            .arg("eval")
            .args(["--extra-experimental-features", "pipe-operator"])
            .arg("--json")
            .arg("--file")
            .arg(nix_file)
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
            .context("Nix output isn't valid UTF-8")?
            .tap(|v| debug!(v, "eval output"))
            .pipe_as_ref(Self::from_str)
    }

    pub fn list_groups(&self) -> impl Iterator<Item = &str> {
        self.packages.iter().map(|p| p.group.as_str())
    }

    pub fn packages_from_group(
        &self,
        name: &str,
    ) -> impl Iterator<Item = &Package> {
        self.packages.iter().filter(move |p| p.group == name)
    }

    pub fn package_need_update(&self) -> impl Iterator<Item = &Package> {
        self.packages.iter().filter(|p| p.update.is_some())
    }
}

#[derive(Debug)]
#[derive(Deserialize)]
pub struct Package {
    pub attr: String,
    pub group: String,
    pub update: Option<Update>,
}

#[derive(Debug)]
#[derive(Deserialize)]
pub struct Update {
    pub version_regex: Option<String>,
    pub unstable_branch: Option<bool>,
    pub preview_release: Option<bool>,
    pub pinned: Option<bool>,
    // subpackages: Vec<Self>,
}
