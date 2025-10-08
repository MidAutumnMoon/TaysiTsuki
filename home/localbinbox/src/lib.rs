use std::fs::DirEntry;
use std::fs::read_dir;
use std::path::Path;
use std::path::PathBuf;

use anyhow::Context;
use anyhow::Result;
use itertools::Itertools;
use tap::Pipe;

#[allow(clippy::missing_errors_doc)]
pub fn collect_read_dir(toplevel: &Path) -> Result<Vec<PathBuf>> {
    read_dir(toplevel)
        .context("Failed to read_dir")?
        .collect::<std::io::Result<Vec<_>>>()
        .context("Failed to collect entries")?
        .iter()
        // TODO: make it absolute?
        .map(DirEntry::path)
        .collect_vec()
        .pipe(Ok)
}
