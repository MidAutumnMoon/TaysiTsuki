use std::path::Path;
use std::str::FromStr;

use anyhow::Context as _;
use anyhow::Result;
use ino_shell::Shell;
use ino_shell::cmd;
use itertools::Itertools as _;
use serde::Deserialize;
use tap::Pipe as _;
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
        let sh = Shell::new()?;
        cmd!(
            sh,
            "nix eval --extra-experimental-features pipe-operator --json --file {nix_file}"
        )
        .read()
        .context("Failed to eval manifest nix")?
        .pipe_as_ref(Self::from_str)
    }

    pub fn list_groups(&self) -> impl Iterator<Item = &str> {
        self.packages
            .iter()
            .map(|p| p.group.as_str())
            .unique()
            .sorted()
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
    /// Custom nix-update version extract regex.
    pub version_regex: Option<String>,

    /// Update source from unstable development branch.
    pub unstable_branch: Option<bool>,

    /// Update to pre-release versions.
    pub preview_release: Option<bool>,

    /// Skip the update.
    pub pinned: Option<bool>,

    /// List of subpackages to also update, the attr name of
    /// the parent package is prepended to it.
    pub subpackages: Option<Vec<String>>,
}

impl Update {
    #[inline]
    pub fn as_nix_update_args(&self) -> Vec<String> {
        let mut accu = vec![];

        if let Some(r) = &self.version_regex {
            accu.push("--version-regex".into());
            accu.push(r.into());
        } else if let Some(b) = &self.unstable_branch
            && *b
        {
            accu.push("--version".into());
            accu.push("branch".into());
        } else if let Some(b) = &self.preview_release
            && *b
        {
            accu.push("--version".into());
            accu.push("unstable".into());
        }

        if let Some(subs) = &self.subpackages {
            for p in subs {
                accu.push("--subpackage".into());
                accu.push(p.into());
            }
        }

        accu
    }
}
