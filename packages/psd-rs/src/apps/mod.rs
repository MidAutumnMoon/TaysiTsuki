//! App profile discovery.
//!
//! Extensible via [`AppKind`]: add a variant, implement discovery in its
//! module, and match in [`AppProfile::discover`].

pub mod cherry_studio;
pub mod chromium;
pub mod firefox;
pub mod telegram;

use std::path::Path;
use std::path::PathBuf;

use anyhow::Context as _;
use anyhow::Result;
use serde::Deserialize;
use strum::AsRefStr;
use strum::EnumIter;

/// Supported apps.
#[derive(
    Debug,
    Clone,
    Copy,
    PartialEq,
    Eq,
    Deserialize,
    EnumIter,
    AsRefStr
)]
#[serde(rename_all = "lowercase")]
#[strum(serialize_all = "lowercase")]
pub enum AppKind {
    Firefox,
    Chromium,
    Telegram,
    CherryStudio,
}

/// How procps `pgrep` can identify an application's process.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ProcessMatch {
    /// Exact `/proc/PID/stat` process name.
    Name(&'static str),
    /// Exact extended regular expression over `/proc/PID/cmdline`.
    CommandLine(&'static str),
}

impl AppKind {
    /// Process name for the running-app check.
    pub const fn process_name(self) -> &'static str {
        match self {
            Self::Firefox => "firefox",
            Self::Chromium => "chromium",
            Self::Telegram => "Telegram",
            Self::CherryStudio => "CherryStudio",
        }
    }

    /// Matcher for the running-app safety check.
    pub const fn process_match(self) -> ProcessMatch {
        match self {
            // Linux process names are limited to 15 bytes. nixpkgs runs
            // Telegram through `.Telegram-wrapped`; other installations use
            // `Telegram` or `telegram-desktop`. Match the complete argv.
            Self::Telegram => ProcessMatch::CommandLine(
                "(^|.*/)([.]Telegram-wrapped|Telegram|telegram-desktop)([[:space:]].*)?",
            ),
            Self::Firefox | Self::Chromium | Self::CherryStudio => {
                ProcessMatch::Name(self.process_name())
            }
        }
    }

    /// Flatpak app-id when this app is sandboxed, else `None` (used
    /// to grant the sandbox tmpfs access).
    pub const fn flatpak_id(self) -> Option<&'static str> {
        match self {
            Self::CherryStudio => Some("com.cherry_ai.CherryStudio"),
            Self::Firefox | Self::Chromium | Self::Telegram => None,
        }
    }
}

/// A single discovered profile directory to manage.
#[derive(Debug, Clone)]
pub struct AppProfile {
    pub kind: AppKind,
    pub user: String,
    /// Absolute path the app writes to (`DIR`).
    pub path: PathBuf,
    /// Final path component, used as a tmpfs disambiguator.
    pub suffix: String,
}

impl AppProfile {
    /// Discover all managed profiles for `kind` under `home`.
    pub fn discover(
        kind: AppKind,
        user: &str,
        home: &Path,
    ) -> Result<Vec<Self>> {
        match kind {
            AppKind::Firefox => firefox::discover(user, home),
            AppKind::Chromium => chromium::discover(user, home),
            AppKind::Telegram => telegram::discover(user, home),
            AppKind::CherryStudio => cherry_studio::discover(user, home),
        }
    }
}

/// Helper for modules: build a profile with the final path component as suffix.
pub fn with_suffix(
    kind: AppKind,
    user: &str,
    path: PathBuf,
) -> Result<AppProfile> {
    let suffix = path
        .file_name()
        .context("profile path has no final component")?
        .to_string_lossy()
        .into_owned();
    Ok(AppProfile {
        kind,
        user: user.to_owned(),
        path,
        suffix,
    })
}

/// Discover a single fixed profile path, including a dangling managed
/// symlink left after the runtime tmpfs disappeared.
pub fn discover_fixed(
    kind: AppKind,
    user: &str,
    path: PathBuf,
) -> Result<Vec<AppProfile>> {
    if !path.is_dir() && !path.is_symlink() {
        return Ok(Vec::new());
    }
    Ok(vec![with_suffix(kind, user, path)?])
}

#[cfg(test)]
#[expect(clippy::unwrap_used, reason = "Test")]
mod tests {
    use super::*;

    use regex::Regex;

    #[test]
    fn telegram_matcher_covers_nixpkgs_command_lines() {
        let ProcessMatch::CommandLine(pattern) =
            AppKind::Telegram.process_match()
        else {
            panic!("Telegram must use full-command-line matching");
        };
        let matcher = Regex::new(&format!("^(?:{pattern})$")).unwrap();

        for command_line in [
            "/nix/store/hash-telegram-desktop-7.0.2/bin/.Telegram-wrapped",
            "/nix/store/hash-telegram-desktop-7.0.2/bin/Telegram -workdir /home/user",
            "/usr/bin/telegram-desktop --startintray",
        ] {
            assert!(
                matcher.is_match(command_line),
                "did not match {command_line}"
            );
        }
        assert!(!matcher.is_match("/usr/bin/bash -c Telegram"));
        assert!(!matcher.is_match("/usr/bin/.Telegram-wrapped-helper"));
    }

    #[test]
    fn fixed_profile_discovers_dangling_managed_path() {
        use std::fs::create_dir_all;
        use std::os::unix::fs::symlink;

        let temp = tempfile::tempdir().unwrap();
        let profile = temp.path().join("app/profile");
        create_dir_all(profile.parent().unwrap()).unwrap();
        symlink(temp.path().join("missing-runtime"), &profile).unwrap();

        let discovered =
            discover_fixed(AppKind::Telegram, "user", profile.clone())
                .unwrap();
        assert_eq!(discovered.len(), 1);
        assert_eq!(discovered.first().unwrap().path, profile);
        assert!(
            discover_fixed(
                AppKind::Telegram,
                "user",
                temp.path().join("missing")
            )
            .unwrap()
            .is_empty()
        );
    }
}
