use std::fs::DirEntry;
use std::fs::read_dir;
use std::io::Result as IoResult;
use std::path::Path;
use std::path::PathBuf;

use anyhow::Context as _;
use anyhow::Result;
use itertools::Itertools as _;
use tap::Pipe as _;

pub mod sops;

#[expect(clippy::missing_errors_doc, reason = "Don't care")]
pub fn collect_read_dir(toplevel: &Path) -> Result<Vec<PathBuf>> {
    read_dir(toplevel)
        .context("Failed to read_dir")?
        .collect::<IoResult<Vec<_>>>()
        .context("Failed to collect entries")?
        .iter()
        .map(DirEntry::path)
        // TODO: ensure relative before join?
        .map(|path| toplevel.join(path))
        .sorted()
        .collect_vec()
        .pipe(Ok)
}
