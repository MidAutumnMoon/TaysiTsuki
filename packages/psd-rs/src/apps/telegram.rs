//! Telegram Desktop data dir discovery.
//!
//! Telegram stores everything (session, media cache, logs) under a single
//! directory at `~/.local/share/TelegramDesktop/`. There is no profile
//! list -- one dir per install.

use std::path::Path;

use anyhow::Result;

use crate::apps::AppKind;
use crate::apps::AppProfile;
use crate::apps::discover_fixed;

pub fn discover(user: &str, home: &Path) -> Result<Vec<AppProfile>> {
    discover_fixed(
        AppKind::Telegram,
        user,
        home.join(".local/share/TelegramDesktop"),
    )
}
