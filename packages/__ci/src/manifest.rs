use std::collections::BTreeMap;
use std::path::Path;
use std::str::FromStr;

use anyhow::Context as _;
use anyhow::Result;
use ino_shell::Shell;
use ino_shell::cmd;
use serde::Deserialize;
use serde::Deserializer;
use serde::de;
use tap::Pipe as _;
use tracing::debug;
use tracing::instrument;

#[derive(Debug)]
pub struct Manifest {
    groups: BTreeMap<String, Vec<Package>>,
}

impl FromStr for Manifest {
    type Err = anyhow::Error;
    fn from_str(input: &str) -> Result<Self, Self::Err> {
        let groups = serde_json::from_str(input)
            .context("Failed to parse manifest")?;
        Ok(Self { groups })
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
        self.groups.keys().map(String::as_str)
    }

    pub fn packages_from_group(
        &self,
        name: &str,
    ) -> impl Iterator<Item = &Package> {
        self.groups.get(name).into_iter().flatten()
    }

    pub fn package_need_update(&self) -> impl Iterator<Item = &Package> {
        self.groups
            .values()
            .flatten()
            .filter(|package| package.track.is_some())
    }
}

/// One manifest entry: what to build, and how it is tracked upstream.
#[derive(Debug)]
#[derive(Deserialize)]
#[serde(deny_unknown_fields)]
pub struct Package {
    /// Attrpath into the flake's package output.
    pub attrpath: String,

    /// How to track upstream with `nix-update`. Absent when the
    /// version is owned elsewhere: first-party packages, or ones
    /// moving with `flake.lock`.
    pub track: Option<Track>,
}

/// How `nix-update` tracks the upstream version.
#[derive(Debug)]
#[derive(Deserialize)]
#[serde(deny_unknown_fields)]
pub struct Track {
    /// How to determine the version to update to.
    pub version: Option<VersionSource>,
}

/// Where the next version comes from.
#[derive(Debug)]
pub enum VersionSource {
    /// A version keyword.
    Named(Named),

    /// A custom version extraction regex.
    Regex(Regex),
}

impl<'de> Deserialize<'de> for VersionSource {
    fn deserialize<D>(deserializer: D) -> Result<Self, D::Error>
    where
        D: Deserializer<'de>,
    {
        let value = serde_json::Value::deserialize(deserializer)?;
        match value {
            serde_json::Value::String(source) => match source.as_str() {
                "branch" => Ok(Self::Named(Named::Branch)),
                "unstable" => Ok(Self::Named(Named::Unstable)),
                _ => Err(de::Error::custom(format!(
                    "unknown version source \"{source}\"; expected \
                     \"branch\", \"unstable\", or an attrset with \"regex\""
                ))),
            },
            value @ serde_json::Value::Object(_) => {
                serde_json::from_value::<Regex>(value)
                    .map(Self::Regex)
                    .map_err(de::Error::custom)
            }
            value @ (serde_json::Value::Null
            | serde_json::Value::Bool(_)
            | serde_json::Value::Number(_)
            | serde_json::Value::Array(_)) => {
                Err(de::Error::custom(format!(
                    "expected a version keyword or an attrset, got {value}"
                )))
            }
        }
    }
}

/// Predefined version keywords.
#[derive(Debug)]
pub enum Named {
    /// Latest commit of the default branch.
    Branch,

    /// Pre-release versions.
    Unstable,
}

/// A `nix-update --version-regex` pattern.
#[derive(Debug)]
#[derive(Deserialize)]
#[serde(deny_unknown_fields)]
pub struct Regex {
    regex: String,
}

impl Track {
    #[inline]
    pub fn as_nix_update_args(&self) -> Vec<String> {
        let mut accu = vec![];

        match &self.version {
            Some(VersionSource::Named(Named::Branch)) => {
                accu.push("--version".into());
                accu.push("branch".into());
            }
            Some(VersionSource::Named(Named::Unstable)) => {
                accu.push("--version".into());
                accu.push("unstable".into());
            }
            Some(VersionSource::Regex(Regex { regex })) => {
                accu.push("--version-regex".into());
                accu.push(regex.clone());
            }
            None => (),
        }

        accu
    }
}

#[cfg(test)]
#[expect(clippy::unwrap_used, reason = "Tests")]
mod tests {
    use serde_json::json;

    use super::Manifest;
    use super::Named;
    use super::Package;
    use super::Track;
    use super::VersionSource;

    fn parse_track(raw: serde_json::Value) -> Track {
        serde_json::from_value(raw).unwrap()
    }

    #[test]
    fn empty_track_gets_defaults() {
        let track = parse_track(json!({}));

        assert!(track.version.is_none());
    }

    #[test]
    fn version_sources_parse() {
        assert!(matches!(
            parse_track(json!({ "version": "branch" })).version,
            Some(VersionSource::Named(Named::Branch))
        ));

        assert!(matches!(
            parse_track(json!({ "version": "unstable" })).version,
            Some(VersionSource::Named(Named::Unstable))
        ));

        assert!(matches!(
            parse_track(
                json!({ "version": { "regex": "v(0\\.1\\..*)" } })
            )
            .version,
            Some(VersionSource::Regex(_))
        ));
    }

    #[test]
    fn unknown_fields_rejected() {
        // These used to be silently ignored, updating with defaults
        // anyway.
        serde_json::from_value::<Track>(
            json!({ "version_regex": "v(.*)" }),
        )
        .unwrap_err();

        serde_json::from_value::<Package>(json!({
            "attrpath": "tsuki.zed",
            "grp": "Small_Trivial_1",
        }))
        .unwrap_err();

        serde_json::from_value::<Package>(json!({
            "attrpath": "tsuki.zed",
            "track": { "pinned": true },
        }))
        .unwrap_err();

        serde_json::from_value::<Track>(json!({
            "version": { "regex": "v(.*)", "extra": true },
        }))
        .unwrap_err();
    }

    #[test]
    fn unknown_version_source_rejected() {
        serde_json::from_value::<Track>(json!({ "version": "stabl" }))
            .unwrap_err();

        // A raw regex is not a keyword; it must be nested in `regex`.
        serde_json::from_value::<Track>(
            json!({ "version": "v(0\\.1\\..*)" }),
        )
        .unwrap_err();
    }

    #[test]
    fn track_absent_or_null_means_not_tracked() {
        let package: Package =
            serde_json::from_value(json!({ "attrpath": "tsuki.zed" }))
                .unwrap();
        assert!(package.track.is_none());

        let package: Package = serde_json::from_value(json!({
            "attrpath": "tsuki.psd-rs",
            "track": null,
        }))
        .unwrap();
        assert!(package.track.is_none());
    }

    #[test]
    fn track_args_map_to_nix_update() {
        let regex =
            parse_track(json!({ "version": { "regex": "app/v(.*)" } }));
        assert_eq!(
            regex.as_nix_update_args(),
            ["--version-regex", "app/v(.*)"]
        );

        let branch = parse_track(json!({ "version": "branch" }));
        assert_eq!(branch.as_nix_update_args(), ["--version", "branch"]);
    }

    #[test]
    fn grouped_wire_format() {
        let manifest: Manifest = r#"
            {
                "Rust_1": [
                    { "attrpath": "zram-generator", "track": null }
                ],
                "Go_1": [
                    { "attrpath": "tsuki.caddy", "track": {} }
                ]
            }
        "#
        .parse()
        .unwrap();

        let groups: Vec<_> = manifest.list_groups().collect();
        assert_eq!(groups, ["Go_1", "Rust_1"]);

        assert_eq!(manifest.packages_from_group("Go_1").count(), 1);
        assert_eq!(manifest.packages_from_group("Nope").count(), 0);

        assert_eq!(manifest.package_need_update().count(), 1);
    }
}
