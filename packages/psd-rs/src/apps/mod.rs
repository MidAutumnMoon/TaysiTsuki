//! App profile discovery.
//!
//! Extensible via [`AppKind`]: add a variant, implement discovery in its
//! module, and match in [`AppProfile::discover`].

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

/// Supported apps. Extend by adding a variant + discover branch.
///
/// The derived string representation (lowercase variant name) serves as
/// both the tmpfs path tag and (by default) the process-name check.
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
}

impl AppKind {
    /// Process name for the "is app running?" check. Used by `pgrep -x`.
    /// Kept as a named method so variants whose binary name differs from
    /// the lowercase kind (e.g. telegram) can override without churning
    /// call sites.
    pub const fn process_name(self) -> &'static str {
        match self {
            Self::Firefox => "firefox",
            Self::Chromium => "chromium",
            Self::Telegram => "telegram-desktop",
        }
    }
}

/// A single discovered profile directory to manage.
#[derive(Debug, Clone)]
pub struct AppProfile {
    pub kind: AppKind,
    pub user: String,
    /// Absolute path the app writes to (DIR in psd terminology).
    pub path: PathBuf,
    /// Final path component, used as a tmpfs disambiguator when an app
    /// can have multiple profiles (firefox). For single-profile apps it
    /// simply echoes the dir name.
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
