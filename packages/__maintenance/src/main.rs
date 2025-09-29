use std::path::Path;
use std::path::PathBuf;

use anyhow::Context;
use anyhow::Result;
use anyhow::bail;
use tap::Pipe;
use tracing::debug;

use crate::manifest::Manifest;
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

/// Do some maintenance work for TaysiTsuki.
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

    /// Build NixOS system.
    #[command(name = "nixos-build")]
    BuildNixOS {
        /// List all
        #[arg(long, short)]
        list_hostnames: bool,
        #[command(flatten)]
        common: CommonOpts,
    },
}

impl App {
    fn manifest(&self) -> &Path {
        match self {
            Self::Update { common } => &common.manifest,
            Self::Build { common, .. } => &common.manifest,
            Self::BuildNixOS { common, .. } => &common.manifest,
        }
    }
}

fn main() -> Result<()> {
    ino_tracing::init_tracing_subscriber();

    let app = <App as clap::Parser>::parse();

    let manifest = app
        .manifest()
        // TODO: Check extension
        .pipe(Manifest::from_eval_nix)
        .context("Failed to load manifest")?;

    debug!(?manifest);

    match app {
        App::Build {
            list_groups, group, ..
        } => {
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
                manifest
                    .packages_from_group(&group)
                    .pipe(build_packages)
                    .context("Failed building")?;
                return Ok(());
            }
            bail!("Nothing to do");
        }

        App::BuildNixOS {
            list_hostnames,
            common,
        } => {
            todo!()
        }

        App::Update { common } => {
            todo!()
        }
    }
}
