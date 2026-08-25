//! Cherry Studio (flatpak) data dir discovery.
//!
//! Electron's `userData` lives under `XDG_CONFIG_HOME` inside the flatpak
//! sandbox, so the on-disk path is
//! `~/.var/app/com.cherry_ai.CherryStudio/config/CherryStudio/`.
//!
//! The flatpak sandbox also needs explicit permission to reach the
//! overlay mount (see [`crate::flatpak::ensure_psd_access`]).

use std::path::Path;

use anyhow::Result;

use crate::apps::AppKind;
use crate::apps::AppProfile;
use crate::apps::discover_fixed;

pub fn discover(user: &str, home: &Path) -> Result<Vec<AppProfile>> {
    discover_fixed(
        AppKind::CherryStudio,
        user,
        home.join(
            ".var/app/com.cherry_ai.CherryStudio/config/CherryStudio",
        ),
    )
}
