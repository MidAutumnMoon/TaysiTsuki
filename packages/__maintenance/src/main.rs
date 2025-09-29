use std::path::Path;
use std::path::PathBuf;

use anyhow::Context;
use anyhow::Result;
use anyhow::bail;
use tap::Pipe;
use tracing::debug;

use crate::manifest::Manifest;
use crate::nixos::build_nixos;
use crate::nixos::eval_hostnames;
use crate::package::build_packages;

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
    #[arg(long, short)]
    working_dir: Option<PathBuf>,
}

/// Do some maintenance work for `TaysiTsuki`.
#[derive(clap::Parser)]
enum App {
    /// Update packages.
    Update {
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
        /// List all hosts from nixos config in flake.
        /// The output is also a JSON array.
        #[arg(long, short)]
        list_hostnames: bool,

        /// Build the `NixOS` with the hostname.
        #[arg(long, short = 'n')]
        hostname: Option<String>,
    },
}

fn main() -> Result<()> {
    ino_tracing::init_tracing_subscriber();

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
                    .pipe(|v| serde_json::json!(v))
                    .pipe(|j| println!("{j}"));
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

        App::Update { common } => {
            let manifest = common
                .manifest
                // TODO: Check extension
                .pipe_as_ref(Manifest::from_eval_nix)
                .context("Failed to load manifest")?;
            debug!(?manifest);
            todo!()
        }
    }
}
