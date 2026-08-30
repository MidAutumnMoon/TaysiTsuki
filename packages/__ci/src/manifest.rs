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
            .map(|package| package.group.as_str())
            .unique()
            .sorted()
    }

    pub fn packages_from_group(
        &self,
        name: &str,
    ) -> impl Iterator<Item = &Package> {
        self.packages
            .iter()
            .filter(move |package| package.group == name)
    }

    pub fn package_need_update(&self) -> impl Iterator<Item = &Package> {
        self.packages
            .iter()
            .filter(|package| package.update.is_some())
    }
}

#[derive(Debug)]
#[derive(Deserialize)]
pub struct Package {
    pub attr: String,
    pub group: String,
    pub update: Option<Update>,
}

/// How to determine the version to update to. At most one can be
/// configured, enforced when deserializing.
#[derive(Debug)]
pub enum VersionSource {
    /// Custom nix-update version extract regex.
    Regex(String),

    /// Update source from unstable development branch.
    Branch,

    /// Update to pre-release versions.
    Unstable,
}

#[derive(Debug)]
#[derive(Deserialize)]
#[serde(try_from = "RawUpdate")]
pub struct Update {
    /// How to determine the version to update to.
    pub version: Option<VersionSource>,

    /// Skip the update.
    pub pinned: bool,

    /// List of subpackages to also update, the attr name of
    /// the parent package is prepended to it.
    pub subpackages: Vec<String>,
}

#[derive(Deserialize)]
struct RawUpdate {
    version_regex: Option<String>,
    unstable_branch: Option<bool>,
    preview_release: Option<bool>,
    pinned: Option<bool>,
    subpackages: Option<Vec<String>>,
}

impl TryFrom<RawUpdate> for Update {
    type Error = String;

    fn try_from(raw: RawUpdate) -> Result<Self, Self::Error> {
        let branch = raw.unstable_branch.unwrap_or(false);
        let unstable = raw.preview_release.unwrap_or(false);

        let version = match (raw.version_regex, branch, unstable) {
            (None, false, false) => None,
            (Some(regex), false, false) => {
                Some(VersionSource::Regex(regex))
            }
            (None, true, false) => Some(VersionSource::Branch),
            (None, false, true) => Some(VersionSource::Unstable),
            _ => {
                return Err("At most one version source can be set".into());
            }
        };

        Ok(Self {
            version,
            pinned: raw.pinned.unwrap_or(false),
            subpackages: raw.subpackages.unwrap_or_default(),
        })
    }
}

impl Update {
    #[inline]
    pub fn as_nix_update_args(&self) -> Vec<String> {
        let mut accu = vec![];

        match &self.version {
            Some(VersionSource::Regex(regex)) => {
                accu.push("--version-regex".into());
                accu.push(regex.clone());
            }
            Some(VersionSource::Branch) => {
                accu.push("--version".into());
                accu.push("branch".into());
            }
            Some(VersionSource::Unstable) => {
                accu.push("--version".into());
                accu.push("unstable".into());
            }
            None => (),
        }

        for sub in &self.subpackages {
            accu.push("--subpackage".into());
            accu.push(sub.into());
        }

        accu
    }
}

#[cfg(test)]
#[expect(clippy::unwrap_used, reason = "Tests")]
mod tests {
    use serde_json::json;

    use super::{Update, VersionSource};

    fn parse(raw: serde_json::Value) -> Update {
        serde_json::from_value(raw).unwrap()
    }

    #[test]
    fn empty_update_gets_defaults() {
        let update = parse(json!({}));

        assert!(update.version.is_none());
        assert!(!update.pinned);
        assert!(update.subpackages.is_empty());
    }

    #[test]
    fn version_sources_parse() {
        assert!(matches!(
            parse(json!({ "version_regex": "v(0\\.1\\..*)" })).version,
            Some(VersionSource::Regex(_))
        ));

        assert!(matches!(
            parse(json!({ "unstable_branch": true })).version,
            Some(VersionSource::Branch)
        ));

        assert!(matches!(
            parse(json!({ "preview_release": true })).version,
            Some(VersionSource::Unstable)
        ));
    }

    #[test]
    fn conflicting_version_sources_rejected() {
        serde_json::from_value::<Update>(json!({
            "version_regex": "v(.*)",
            "unstable_branch": true,
        }))
        .unwrap_err();
    }
}
