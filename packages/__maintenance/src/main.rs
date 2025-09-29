use std::path::PathBuf;

use anyhow::Result;

mod listing;
mod manifest;
mod update;

/// Do some maintenance work for TaysiTsuki.
#[derive(clap::Parser)]
enum App {
    /// Update packages.
    Update {
        dir: PathBuf,
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
        #[command(flatten)]
        common: CommonOpts,
    },

    /// Build NixOS system.
    BuildNixOS {
        /// List all
        #[arg(long, short)]
        list_hostnames: bool,
        #[command(flatten)]
        common: CommonOpts,
    },
}

#[derive(clap::Args)]
#[derive(Debug)]
#[derive(Clone)]
struct CommonOpts {
    #[arg(long, short)]
    working_dir: Option<PathBuf>,
}

fn main() -> Result<()> {
    let app = <App as clap::Parser>::parse();

    Ok(())
}
