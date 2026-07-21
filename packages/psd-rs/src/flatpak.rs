//! Flatpak sandbox permissions for psd-managed apps.
//!
//! A flatpak sandbox cannot see `$XDG_RUNTIME_DIR/psd` by default, so
//! the overlay mount we create would be unreachable from inside the app.
//! We grant per-app access via `flatpak override --user --filesystem=`,
//! matching what upstream psd does in its `firefox-flatpak` contrib.
//!
//! Idempotent: re-running with the permission already granted is a
//! no-op. Safe to call every startup.

use std::process::Command;

use anyhow::Context;
use anyhow::Result;
use anyhow::bail;
use tracing::info;

/// Ensure the flatpak `app_id` has filesystem access to the psd tmpfs.
/// No-op if already granted.
pub fn ensure_psd_access(app_id: &str) -> Result<()> {
    let uid = nix::unistd::getuid().as_raw();
    let psd_path = format!("/run/user/{uid}/psd");

    if has_filesystem(app_id, &psd_path)? {
        return Ok(());
    }

    info!(app_id, path = %psd_path, "granting flatpak filesystem access");
    let status = Command::new("flatpak")
        .args([
            "override",
            "--user",
            app_id,
            &format!("--filesystem={psd_path}"),
        ])
        .status()
        .context("spawning flatpak override")?;
    if !status.success() {
        bail!(
            "flatpak override failed for {app_id} (exit {})",
            status.code().unwrap_or(-1)
        );
    }
    Ok(())
}

/// True if `flatpak override --user --show <app_id>` already mentions `path`.
fn has_filesystem(app_id: &str, path: &str) -> Result<bool> {
    let out = Command::new("flatpak")
        .args(["override", "--user", "--show", app_id])
        .output()
        .context("spawning flatpak override --show")?;
    // Non-zero exit just means no overrides set yet.
    let text = String::from_utf8_lossy(&out.stdout);
    Ok(text.contains(path))
}
