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

use anyhow::Context;
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

impl AppKind {
    /// Process name for the running-app check.
    pub const fn process_name(self) -> &'static str {
        match self {
            Self::Firefox => "firefox",
            Self::Chromium => "chromium",
            Self::Telegram => "telegram-desktop",
            Self::CherryStudio => "CherryStudio",
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
