//! Cherry Studio (flatpak) data dir discovery.
//!
//! Cherry Studio is an Electron app distributed as a flatpak
//! (`com.cherry_ai.CherryStudio`). Electron's `userData` lives under
//! `XDG_CONFIG_HOME` inside the sandbox, so the on-disk path is
//! `~/.var/app/com.cherry_ai.CherryStudio/config/CherryStudio/`.
//!
//! One quirk vs. native apps: the flatpak sandbox needs explicit
//! permission to reach the overlay mount in `$XDG_RUNTIME_DIR/psd`. See
//! [`crate::flatpak::ensure_psd_access`], invoked from `cmd_startup`.

use std::path::Path;

use anyhow::Result;

use crate::apps::AppKind;
use crate::apps::AppProfile;
use crate::apps::with_suffix;

pub fn discover(user: &str, home: &Path) -> Result<Vec<AppProfile>> {
    let dir = home
        .join(".var/app/com.cherry_ai.CherryStudio/config/CherryStudio");
    if !dir.is_dir() {
        return Ok(Vec::new());
    }
    Ok(vec![with_suffix(AppKind::CherryStudio, user, dir)?])
}
