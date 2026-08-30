use std::fs::read_to_string;
use std::path::Path;
use std::process::Command;
use std::sync::atomic::AtomicBool;
use std::sync::atomic::Ordering;

use anyhow::Context as _;
use anyhow::Result;
use anyhow::bail;
use anyhow::ensure;
use itertools::Itertools as _;
use rayon::ThreadPoolBuilder;
use rayon::iter::IntoParallelIterator as _;
use rayon::iter::ParallelIterator as _;
use tap::Pipe as _;
use tempfile::NamedTempFile;
use tracing::debug;
use tracing::debug_span;
use tracing::instrument;

use crate::git_toplevel;
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
pub fn build_packages<'pkg>(
    packages: impl IntoIterator<Item = &'pkg Package>,
) -> Result<()> {
    debug!("Build packages");

    let attrs = packages
        .into_iter()
        .map(|package| format!(".#{}", package.attr))
        .collect::<Vec<_>>();

    if attrs.is_empty() {
        bail!("No package selected to build");
    }

    debug!(?attrs, "Attrs for nix to build");

    let status = Command::new("nix")
        .arg("build")
        .args(NIX_BUILD_OPTS)
        .args(attrs)
        .status()
        .context("Failed to run nix build command")?;

    ensure!(status.success(), "Nix build failed");
    Ok(())
}

#[instrument(skip_all)]
pub fn update_all_packages<'pkg>(
    packages: impl IntoIterator<Item = &'pkg Package> + Send,
) -> Result<String> {
    debug!("Update packages");

    let toplevel = git_toplevel().context("Failed to get git toplevel")?;
    let packages = packages.into_iter().collect::<Vec<_>>();

    let pool = ThreadPoolBuilder::new()
        .num_threads(6)
        .build()
        .context("Failed to create threadpool")?;

    // Stop starting new nix-update runs once one fails. Ones already
    // running still finish, as child processes can't be preempted.
    let cancelled = AtomicBool::new(false);

    let results = pool.install(move || {
        packages
            .into_par_iter()
            .map(|package| {
                if cancelled.load(Ordering::Relaxed) {
                    debug!(?package, "Cancelled by earlier failure");
                    return Ok(None);
                }
                let res = debug_span!("update_package", ?package)
                    .in_scope(|| update_one_package(package, &toplevel))
                    .with_context(|| {
                        format!("Failed to update {}", package.attr)
                    });
                if res.is_err() {
                    cancelled.store(true, Ordering::Relaxed);
                }
                res
            })
            .collect::<Vec<_>>()
    });

    let mut summaries = Vec::new();
    let mut errors = Vec::new();

    for res in results {
        match res {
            Ok(Some(summary)) => summaries.push(summary),
            Ok(None) => (),
            Err(err) => errors.push(err),
        }
    }

    ensure!(
        errors.is_empty(),
        "Failed to update {} package(s):\n{}",
        errors.len(),
        errors.iter().map(|error| format!("{error:#}")).join("\n"),
    );

    Ok(summaries.join("\n\n"))
}

#[instrument]
fn update_one_package(
    package: &Package,
    toplevel: &Path,
) -> Result<Option<String>> {
    let Some(update) = &package.update else {
        debug!("Package not opt into update");
        return Ok(None);
    };

    if update.pinned {
        debug!("Package pinned");
        return Ok(None);
    }

    let commit_message_file = NamedTempFile::new()
        .context("Failed to create tempfile to store update summary")?;

    debug!(
        "temporary file to store commit message {}",
        commit_message_file.path().display()
    );

    match Command::new("nix-update")
        .current_dir(toplevel)
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
                .pipe(|message| {
                    if message.trim().is_empty() {
                        None
                    } else {
                        // Add Markdown heading so that it looks nicer in
                        // pull request.
                        Some(format!("## {message}"))
                    }
                })
                .pipe(Ok)
        }
        Err(err) => Err(anyhow::Error::from(err))
            .context("Failed to run nix-update"),
    }
}
