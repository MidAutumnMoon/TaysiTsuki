//! Flatpak sandbox permissions for psd-managed apps.
//!
//! A sandbox cannot see the psd tmpfs by default, so the overlay
//! mount would be unreachable from inside the app. Access is granted
//! per app via `flatpak override --user --filesystem=`; idempotent.

use std::path::Path;
use std::process::Command;

use anyhow::Context as _;
use anyhow::Result;
use tracing::info;

use crate::exec;

/// Ensure the flatpak `app_id` has filesystem access to `psd_path`
/// (the psd tmpfs root). No-op if already granted.
pub fn ensure_psd_access(app_id: &str, psd_path: &Path) -> Result<()> {
    let psd_path = psd_path.display().to_string();

    if has_filesystem(app_id, &psd_path)? {
        return Ok(());
    }

    info!(app_id, path = %psd_path, "granting flatpak filesystem access");
    exec::run(Command::new("flatpak").args([
        "override",
        "--user",
        app_id,
        &format!("--filesystem={psd_path}"),
    ]))
    .with_context(|| format!("flatpak override for {app_id}"))
}

/// True if `flatpak override --user --show <app_id>` already grants
/// `path`.
fn has_filesystem(app_id: &str, path: &str) -> Result<bool> {
    let out = exec::output(
        Command::new("flatpak")
            .args(["override", "--user", "--show", app_id]),
    )?;
    // Non-zero exit just means no overrides set yet.
    let text = String::from_utf8_lossy(&out.stdout);
    Ok(parse_has_filesystem(&text, path))
}

/// Exact token match against the `filesystems=` list -- substring
/// matching would false-positive on longer paths and skip a needed
/// grant.
fn parse_has_filesystem(show_output: &str, path: &str) -> bool {
    show_output
        .lines()
        .filter_map(|l| l.trim().strip_prefix("filesystems="))
        .any(|v| v.split(';').any(|t| t.trim() == path))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn filesystem_tokens_match_exactly() {
        for (show, expected) in [
            ("[Context]\nfilesystems=host;/run/user/1000/psd;\n", true),
            ("[Context]\nfilesystems=/run/user/1000/psd-other;\n", false),
            ("[Context]\nshared=network;\n", false),
        ] {
            assert_eq!(
                parse_has_filesystem(show, "/run/user/1000/psd"),
                expected
            );
        }
    }
}
