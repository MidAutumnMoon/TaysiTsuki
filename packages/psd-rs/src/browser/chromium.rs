//! Chromium profile discovery.
//!
//! Chromium stores profile list in `~/.config/chromium/local_state`
//! (JSON). Each profile dir lives under `~/.config/chromium/<dir>`.
//! `Default` is always present; others are named `Profile N`.

use std::collections::BTreeMap;
use std::path::Path;

use anyhow::Context;
use anyhow::Result;
use serde::Deserialize;
use tracing::debug;
use tracing::warn;

use crate::browser::with_suffix;
use crate::browser::BrowserKind;
use crate::browser::BrowserProfile;

pub fn discover(user: &str, home: &Path) -> Result<Vec<BrowserProfile>> {
    let base = home.join(".config/chromium");
    let local_state = base.join("local_state");
    if !local_state.is_file() {
        return Ok(Vec::new());
    }
    debug!(path = %local_state.display(), "parsing chromium local_state");
    let raw = std::fs::read_to_string(&local_state)
        .with_context(|| format!("reading {}", local_state.display()))?;
    let parsed: LocalState = serde_json::from_str(&raw)
        .with_context(|| format!("parsing {}", local_state.display()))
        .inspect_err(|e| warn!(error = %e, path = %local_state.display(), "local_state parse failed"))
        .unwrap_or_default();

    let mut out = Vec::new();
    // `info_cache` keys are profile dir names: "Default", "Profile 1", ...
    for name in parsed.profile.info_cache.keys() {
        out.push(with_suffix(
            BrowserKind::Chromium,
            user,
            base.join(name),
        )?);
    }
    Ok(out)
}

#[derive(Debug, Default, Deserialize)]
struct LocalState {
    #[serde(default)]
    profile: Profile,
}

#[derive(Debug, Default, Deserialize)]
struct Profile {
    #[serde(default)]
    info_cache: BTreeMap<String, serde_json::Value>,
}

#[cfg(test)]
mod tests {
    // Note: the local_state format is fragile; integration tests belong in
    // a fixture directory rather than inline JSON. Skip for now.
}
