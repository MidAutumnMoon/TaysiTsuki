use std::env::current_dir;
use std::process::Command;

use anyhow::Context as _;
use anyhow::bail;
use anyhow::ensure;
use gix_discover::repository;
use ino_color::ceprintln;
use ino_color::fg::Yellow;
use localbinbox::sops::find_sops_encrypted_files;
use tracing::debug;

fn main() -> anyhow::Result<()> {
    let _log_guard = ino_tracing::init_tracing_subscriber();

    let toplevel = {
        debug!("Get git repository toplevel");
        let cwd = current_dir()?;
        // trust discarded
        let (path, _) = gix_discover::upwards(&cwd)
            .context("Failed to locate git repo toplevel")?;

        #[expect(clippy::wildcard_enum_match_arm, reason = "Don't care")]
        match path {
            repository::Path::WorkTree(path) => path,
            _ => bail!("Other types of repo are not handled"),
        }
    };

    ceprintln!(Yellow, "Toplevel {}", toplevel.display());

    let sops_files = find_sops_encrypted_files(toplevel)?;

    ceprintln!(
        Yellow,
        "Attempt to update keys for {} sops files",
        sops_files.len()
    );

    for file in sops_files {
        let ret = Command::new("sops")
            .arg("updatekeys")
            .arg("-y")
            .arg(file.path())
            .spawn()
            .context("Failed to spawn sops command")?
            .wait()
            .context("Failed to wait for sops")?;
        ensure!(ret.success(), "sops command failed");
    }

    Ok(())
}
