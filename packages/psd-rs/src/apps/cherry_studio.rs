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
use crate::apps::with_suffix;

pub fn discover(user: &str, home: &Path) -> Result<Vec<AppProfile>> {
    let dir = home
        .join(".var/app/com.cherry_ai.CherryStudio/config/CherryStudio");
    if !dir.is_dir() && !dir.is_symlink() {
        return Ok(Vec::new());
    }
    Ok(vec![with_suffix(AppKind::CherryStudio, user, dir)?])
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
        let profile = temp.path().join(
            ".var/app/com.cherry_ai.CherryStudio/config/CherryStudio",
        );
        create_dir_all(profile.parent().unwrap()).unwrap();
        symlink(temp.path().join("missing-runtime"), &profile).unwrap();

        let discovered = discover("user", temp.path()).unwrap();
        assert_eq!(discovered.len(), 1);
        assert_eq!(discovered.first().unwrap().path, profile);
    }
}
