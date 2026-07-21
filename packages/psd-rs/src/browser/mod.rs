//! Browser profile discovery.
//!
//! Extensible via [`BrowserKind`]: add a variant, implement discovery in
//! its module, and match in [`BrowserProfile::discover`].

pub mod chromium;
pub mod firefox;

use std::path::Path;
use std::path::PathBuf;

use anyhow::Context;
use anyhow::Result;
use serde::Deserialize;
use strum::AsRefStr;
use strum::EnumIter;

/// Supported browsers. Extend by adding a variant + discover branch.
///
/// The derived string representation (lowercase variant name) serves as
/// both the tmpfs path tag and the process-name check.
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
pub enum BrowserKind {
    Firefox,
    Chromium,
}

impl BrowserKind {
    /// Process name for the "is browser running?" check.
    /// Currently equal to `as_ref()`, kept as a named method so a future
    /// variant (e.g. firefox-esr) can override without churning call sites.
    pub const fn process_name(self) -> &'static str {
        match self {
            Self::Firefox => "firefox",
            Self::Chromium => "chromium",
        }
    }
}

/// A single discovered profile directory to manage.
#[derive(Debug, Clone)]
pub struct BrowserProfile {
    pub kind: BrowserKind,
    pub user: String,
    /// Absolute path the browser writes to (DIR in psd terminology).
    pub path: PathBuf,
    /// Final path component, used as a tmpfs disambiguator when a browser
    /// can have multiple profiles (firefox). Empty for single-profile.
    pub suffix: String,
}

impl BrowserProfile {
    /// Discover all managed profiles for `kind` under `home`.
    pub fn discover(
        kind: BrowserKind,
        user: &str,
        home: &Path,
    ) -> Result<Vec<Self>> {
        match kind {
            BrowserKind::Firefox => firefox::discover(user, home),
            BrowserKind::Chromium => chromium::discover(user, home),
        }
    }

    /// True if `suffix` should be applied to tmpfs names. Only firefox-family
    /// browsers can have multiple profiles per install.
    pub fn needs_suffix(&self) -> bool {
        matches!(self.kind, BrowserKind::Firefox)
    }
}

/// Helper for modules: build a profile with the final path component as suffix.
pub fn with_suffix(
    kind: BrowserKind,
    user: &str,
    path: PathBuf,
) -> Result<BrowserProfile> {
    let suffix = path
        .file_name()
        .context("profile path has no final component")?
        .to_string_lossy()
        .into_owned();
    Ok(BrowserProfile {
        kind,
        user: user.to_owned(),
        path,
        suffix,
    })
}
