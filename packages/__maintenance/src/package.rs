use std::env::set_current_dir;
use std::fs::read_to_string;
use std::iter::repeat;
use std::process::Command;
use std::sync::Arc;
use std::sync::Mutex;
use std::sync::mpsc::channel;

use anyhow::Context;
use anyhow::Result;
use anyhow::bail;
use anyhow::ensure;
use itertools::izip;
use rayon::ThreadPoolBuilder;
use tap::Pipe;
use tempfile::NamedTempFile;
use tracing::debug;
use tracing::debug_span;
use tracing::instrument;
use tracing::warn;

use crate::cmd::capture_cmd_output;
use crate::manifest::Package;

#[rustfmt::skip]
pub static NIX_BUILD_OPTS: &[&str] = &[
    "--no-link",
    "--print-build-logs",
    "--keep-failed",
    "--show-trace",
    "--option", "narinfo-cache-negative-ttl", "0",
    "--option", "keep-going", "true",
    "--option", "max-jobs", "1",
];

#[instrument(skip_all)]
pub fn build_packages<'a>(
    packages: impl IntoIterator<Item = &'a Package>,
) -> Result<()> {
    debug!("Build packages");

    let attrs = packages
        .into_iter()
        .map(|p| format!(".#{}", &p.attr))
        .collect::<Vec<_>>();

    if attrs.is_empty() {
        bail!("No package selected to build");
    }

    debug!(?attrs, "Attrs for nix to build");

    let status = Command::new("nix")
        .arg("build")
        .args(NIX_BUILD_OPTS)
        .args(attrs)
        .spawn()
        .context("Failed to spawn nix build command")?
        .wait()
        .context("Failed waiting nix build child process")?;

    ensure!(status.success(), "Nix build failed");
    Ok(())
}

enum Permit {
    GoAhead,
    Cancel,
}

#[instrument(skip_all)]
pub fn update_all_packages<'a>(
    packages: impl IntoIterator<Item = &'a Package> + Send,
) -> Result<String> {
    debug!("Update packages");

    let pool = ThreadPoolBuilder::new()
        .num_threads(6)
        .build()
        .context("Failed to create threadpool")?;

    pool.scope(move |scope| {
        let permit = Mutex::new(Permit::GoAhead).pipe(Arc::new);
        let (res_sender, res_receiver) = channel::<Result<String>>();

        let toplevel =
            capture_cmd_output("git", &["rev-parse", "--show-toplevel"])?
                .pipe(Arc::new);

        for (package, permit, sender, toplevel) in izip!(
            packages,
            repeat(permit),
            repeat(res_sender),
            repeat(toplevel)
        ) {
            scope.spawn(move |_| {
                let _s = debug_span!("update_package", ?package).entered();
                if matches!(
                    *permit.lock().expect("Failed to accquire mutex"),
                    Permit::Cancel
                ) {
                    return;
                }
                match update_one_package(package, &toplevel) {
                    Ok(Some(summary)) => {
                        let _ = sender.send(Ok(summary));
                    }
                    // If error, cancel future tasks, best effort as
                    // it doesn't really matter that much.
                    Err(err) => {
                        debug!(?package, "Failed to update package");
                        *permit
                            .lock()
                            .expect("Failed to accquire mutex") =
                            Permit::Cancel;
                        let _ = sender.send(Err(err));
                    }
                    Ok(None) => (),
                }
            });
        }

        let mut accu = String::new();

        for res in res_receiver {
            match res {
                Ok(summary) => {
                    accu.push('\n');
                    accu.push_str(&summary);
                }
                Err(e) => {
                    return Err(e.context("Error while updating package"));
                }
            }
        }

        Ok(accu)
    })
}

#[instrument]
fn update_one_package(
    package: &Package,
    toplevel: &str,
) -> Result<Option<String>> {
    let Some(update) = &package.update else {
        debug!("Package not opt into update");
        return Ok(None);
    };

    if matches!(update.pinned, Some(true)) {
        debug!("Package pinned");
        return Ok(None);
    }

    set_current_dir(toplevel).context("Failed to switch working dir")?;

    let commit_message_file = NamedTempFile::new()
        .context("Failed to create tempfile to store update summary")?;

    debug!(
        "temporary file to store commit message {}",
        commit_message_file.path().display()
    );

    match Command::new("nix-update")
        .args(update.as_nix_update_args())
        .arg("--use-github-releases")
        .arg("--write-commit-message")
        .arg(commit_message_file.path())
        .arg("--flake")
        .arg(&package.attr)
        .output()
    {
        Ok(output) => {
            if !output.status.success() {
                bail!(
                    "nix-update exited with error.\nStderr:\n{}",
                    String::from_utf8_lossy(&output.stderr)
                )
            }
            read_to_string(commit_message_file.path())
                .context("Failed to read commit message from file")?
                .pipe(|s| {
                    if s.trim().is_empty() {
                        None
                    } else {
                        // Add markdown heading so that it looks nicer in
                        // pull request.
                        Some(format!("## {s}"))
                    }
                })
                .pipe(Ok)
        }
        Err(err) => Err(anyhow::Error::from(err))
            .context("Failed to run nix-update"),
    }
}
