use std::fmt::Debug;
use std::fs::read_to_string;
use std::path::Path;
use std::path::PathBuf;

use ignore::WalkBuilder;
use saphyr::LoadableYamlNode as _;
use saphyr::Yaml;
use tracing::debug;
use tracing::instrument;

#[expect(clippy::module_name_repetitions, reason = "More descriptive")]
#[derive(Debug)]
pub struct SopsFile {
    path: PathBuf,
}

impl SopsFile {
    #[must_use]
    pub fn path(&self) -> &Path {
        &self.path
    }
}

/// Find all files within `toplevel` that looks like
/// to be encrypted by sops. This is best effort as it doesn't really matter
/// if gets it wrong.
#[expect(clippy::missing_errors_doc, reason = "Don't care")]
#[instrument]
pub fn find_sops_encrypted_files(
    toplevel: impl AsRef<Path> + Debug,
) -> anyhow::Result<Vec<SopsFile>> {
    let toplevel = toplevel.as_ref();
    let files = collect_files(toplevel)?;
    let mut accu = vec![];

    // No way near to be a performance problem at this scale.
    for file in files {
        let content = read_to_string(&file)?;
        if guess_encrypted(&content) {
            accu.push(SopsFile { path: file });
        }
    }
    Ok(accu)
}

#[inline]
#[instrument(skip(content))]
fn guess_encrypted(content: &str) -> bool {
    // The YAML parser can handle both YAML and JSON
    if let Ok(docs) = Yaml::load_from_str(content) {
        // `sops-nix` doesn't support multiple documents,
        // ignored for now. This also covers empty document scenario
        let [doc] = docs.as_slice() else {
            debug!("Not support YAML document");
            return false;
        };
        // If the document contains "sops" field and "age.version",
        // it's probably age encrypted.
        if let Some(doc) = doc.as_mapping_get("sops")
            && doc.as_mapping_get("version").is_some()
        {
            return true;
        }
    }
    debug!("Nothing recognised");
    false
}

#[instrument(skip_all)]
fn collect_files(toplevel: &Path) -> anyhow::Result<Vec<PathBuf>> {
    debug!("Collect files");
    let mut accu = vec![];
    for entry in WalkBuilder::new(toplevel)
        .standard_filters(true)
        .follow_links(false)
        .hidden(false)
        .filter_entry(|entry| entry.file_name() != ".git")
        .current_dir(toplevel)
        .build()
    {
        let entry = entry?;
        if entry.file_type().is_some_and(|filetype| !filetype.is_dir()) {
            accu.push(entry.path().to_owned());
        }
    }
    Ok(accu)
}
