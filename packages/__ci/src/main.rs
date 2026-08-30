use std::path::PathBuf;

use anyhow::Context as _;
use anyhow::Result;
use anyhow::bail;
use gix_discover::repository;
use tap::Pipe as _;
use tracing::debug;

use crate::manifest::Manifest;
use crate::nixos::build_nixos;
use crate::nixos::eval_hostnames;
use crate::package::build_packages;
use crate::package::update_all_packages;

mod manifest;
mod nixos;
mod package;

#[derive(clap::Args)]
#[derive(Debug)]
#[derive(Clone)]
struct CommonOpts {
    /// The manifest for what packages to build and update.
    #[arg(long, short)]
    manifest: PathBuf,
}

/// Do some maintenance work for `TaysiTsuki`.
#[derive(clap::Parser)]
enum App {
    /// Update packages.
    Update {
        /// Write update summary to file.
        #[arg(long, short)]
        write_update_summary: Option<PathBuf>,

        #[command(flatten)]
        common: CommonOpts,
    },

    /// Build packages.
    Build {
        /// List the names of build group. The output is a JSON array.
        /// This is intended to be used with GitHub Action matrix
        /// to parallelize builds.
        #[arg(long, short)]
        list_groups: bool,

        /// Select the group to build.
        #[arg(long, short)]
        group: Option<String>,

        #[command(flatten)]
        common: CommonOpts,
    },

    /// Build `NixOS` system.
    #[command(name = "nixos")]
    NixOS {
        /// List all hosts from NixOS config in flake.
        /// The output is also a JSON array.
        #[arg(long, short)]
        list_hostnames: bool,

        /// Build the `NixOS` with the hostname.
        #[arg(long, short = 'n')]
        hostname: Option<String>,
    },
}

fn main() -> Result<()> {
    let _log_guard = ino_tracing::init_tracing_subscriber();

    let app = <App as clap::Parser>::parse();

    match app {
        App::Build {
            list_groups,
            group,
            common,
        } => {
            let manifest = common
                .manifest
                // TODO: Check extension
                .pipe_as_ref(Manifest::from_eval_nix)
                .context("Failed to load manifest")?;
            debug!(?manifest);

            if list_groups {
                debug!("Print group names in JSON");
                manifest
                    .list_groups()
                    .collect::<Vec<_>>()
                    .pipe(|groups| serde_json::json!(groups))
                    .pipe(|json| println!("{json}"));
                return Ok(());
            }
            if let Some(group) = group {
                debug!("Build packages from group {group}");
                return manifest
                    .packages_from_group(&group)
                    .pipe(build_packages)
                    .context("Failed building");
            }
            bail!("Nothing to do");
        }

        App::NixOS {
            list_hostnames,
            hostname,
        } => {
            if list_hostnames {
                debug!("List hostnames");
                eval_hostnames()
                    .context("Failed to eval hostnames")?
                    .pipe(|j| println!("{j}"));
                return Ok(());
            }
            if let Some(hostname) = hostname {
                debug!("Build NixOS {hostname}");
                return build_nixos(&hostname)
                    .context("Failed building NixOS");
            }
            bail!("Nothing to do");
        }

        App::Update {
            common,
            write_update_summary,
        } => {
            let manifest = common
                .manifest
                // TODO: Check extension
                .pipe_as_ref(Manifest::from_eval_nix)
                .context("Failed to load manifest")?;
            debug!(?manifest);
            let summary = manifest
                .package_need_update()
                .pipe(update_all_packages)
                .context("Failed to update package")?;
            if let Some(report) = write_update_summary {
                std::fs::write(&report, &summary)
                    .context("Failed to write update summary to file")?;
            } else {
                println!("{summary}");
            }
            Ok(())
        }
    }
}

#[tracing::instrument]
fn git_toplevel() -> Result<PathBuf> {
    debug!("Get git repository toplevel");
    let cwd = std::env::current_dir()?;
    // trust discarded
    let (path, _) = gix_discover::upwards(&cwd)
        .context("Failed to locate git repo toplevel")?;
    match path {
        repository::Path::WorkTree(path) => Ok(path),
        repository::Path::LinkedWorkTree { .. }
        | repository::Path::Repository(_) => {
            bail!("Other types of repo are not handled")
        }
    }
}
