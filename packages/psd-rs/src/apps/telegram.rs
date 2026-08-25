//! Telegram Desktop data dir discovery.
//!
//! Telegram stores everything (session, media cache, logs) under a single
//! directory at `~/.local/share/TelegramDesktop/`. There is no profile
//! list -- one dir per install.

use std::path::Path;

use anyhow::Result;

use crate::apps::AppKind;
use crate::apps::AppProfile;
use crate::apps::with_suffix;

pub fn discover(user: &str, home: &Path) -> Result<Vec<AppProfile>> {
    let dir = home.join(".local/share/TelegramDesktop");
    if !dir.is_dir() && !dir.is_symlink() {
        return Ok(Vec::new());
    }
    Ok(vec![with_suffix(AppKind::Telegram, user, dir)?])
}

#[cfg(test)]
#[expect(clippy::unwrap_used, reason = "Test")]
mod tests {
    use std::fs::create_dir_all;
    use std::os::unix::fs::symlink;

    use super::*;

    use tempfile::tempdir;

    #[test]
    fn discovers_dangling_managed_path_for_recovery() {
        let temp = tempdir().unwrap();
        let profile = temp.path().join(".local/share/TelegramDesktop");
        create_dir_all(profile.parent().unwrap()).unwrap();
        symlink(temp.path().join("missing-runtime"), &profile).unwrap();

        let discovered = discover("user", temp.path()).unwrap();
        assert_eq!(discovered.len(), 1);
        assert_eq!(discovered.first().unwrap().path, profile);
    }
}
