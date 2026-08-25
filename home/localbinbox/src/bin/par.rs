use std::env;
use std::env::current_dir;
use std::env::set_current_dir;
use std::fs;
use std::path::Path;
use std::path::PathBuf;
use std::process::Command;

use anyhow::Context as _;
use anyhow::Result;
use anyhow::bail;
use anyhow::ensure;
use ino_color::ceprintln;
use ino_color::fg::Blue;
use ino_color::fg::Yellow;
use ino_iter::InoIter as _;
use itertools::Itertools as _;
use localbinbox::collect_read_dir;

const CFG_PAR2: Option<&str> = option_env!("CFG_PAR2");

fn main() -> Result<()> {
    let paths = {
        let args = env::args().skip(1).collect_vec();
        let cwd = current_dir()?;
        let inputs = if args.is_empty() {
            ceprintln!(Yellow, "No files, read current dir");
            collect_read_dir(&cwd)?
        } else {
            args.into_iter()
                .map(|path| {
                    let path = Path::new(&path);
                    if path.is_absolute() {
                        path.to_owned()
                    } else {
                        cwd.join(path)
                    }
                })
                .collect_vec()
        };
        ensure!(
            inputs.iter().all(|path| path.exists()),
            "Some path does not exits or not accessible"
        );
        ensure!(
            inputs.iter().all(|path| path.is_absolute()),
            "[BUG] Paths must all be absolute"
        );
        inputs
    };

    for path in paths {
        par(&path).context("Error while processing path")?;
    }

    Ok(())
}

/// Generate par2archive files.
fn par(path: &Path) -> Result<()> {
    enum PathType {
        File,
        Dir,
    }

    ensure!(path.is_absolute(), "{} is not absolute", path.display());

    // N.B. symlink not checked as it's very rare for most use cases.
    let path_type = if path.is_file() {
        ceprintln!(Yellow, "File mode");
        PathType::File
    } else if path.is_dir() {
        ceprintln!(Yellow, "Directory mode");
        PathType::Dir
    } else {
        bail!("{} is neither file nor dir", path.display())
    };

    ceprintln!(Yellow, "Par2archive for {}", basename_of(path)?);

    let src_files = match path_type {
        PathType::Dir => collect_read_dir(path)?
            .into_iter()
            .select(|path| path.is_file())
            .collect(),
        PathType::File => vec![path.to_owned()],
    };

    ensure!(
        src_files.iter().all(|file| file.is_absolute()),
        "[BUG] Some paths are not absolute"
    );

    ensure!(
        src_files.iter().all(|file| file.is_file()),
        "[BUG] Some paths are not files"
    );

    for file in &src_files {
        let parent = parent_of(file)?;
        let basename = basename_of(file)?;
        ensure!(!basename.is_empty());

        ceprintln!(Blue, "Par2archive file {basename}");

        let status = Command::new(CFG_PAR2.unwrap_or("par2"))
            // Set cwd so that the files can be referred to with
            // just basename, and it also makes generated
            // par2archive path independent.
            .current_dir(parent)
            .arg("create")
            // 1 volume file
            .arg("-n1")
            // 5% of redundancy
            .arg("-r5")
            .arg("-q")
            .arg("--")
            // N.B. set current dir above.
            .arg(basename)
            .spawn()
            .context("Failed to spawn par2")?
            .wait()?;

        ensure!(status.success(), "Par2 exited with error");

        // Par2 index file is not essential to recovery
        // so delete it reduce the file count
        let par2_index_name = format!("{basename}.par2");
        fs::remove_file(Path::new(&par2_index_name))
            .context("Failed to remove par2 index file")?;

        let par2_volume = match &*par2_volumes(parent, basename)? {
            [volume] => volume.clone(),
            [_v, ..] => bail!("[BUG] Found multiple par2 volume"),
            [] => bail!("[BUG] No par2 volume found"),
        };

        ensure!(par2_volume.is_absolute());

        // N.B. chdir into parent
        fs::rename(&par2_volume, parent.join(par2_index_name))
            .context("Failed to rename par2 index file")?;
    }

    Ok(())
}

#[inline]
fn basename_of(path: &Path) -> Result<&str> {
    if let Some(basename) = path.file_name()
        && let Some(basename) = basename.to_str()
    {
        Ok(basename)
    } else {
        bail!("Path {} does not have a valid basename", path.display())
    }
}

#[inline]
fn parent_of(path: &Path) -> Result<&Path> {
    if let Some(parent_dir) = path.parent() {
        Ok(parent_dir)
    } else {
        bail!("Path {} does not have parent", path.display())
    }
}

#[inline]
fn par2_volumes(parent: &Path, name: &str) -> Result<Vec<PathBuf>> {
    let mut accu = vec![];
    for file in collect_read_dir(parent)? {
        let basename = basename_of(&file)?;
        if basename
            .strip_circumfix(&format!("{name}.vol"), "par2")
            .is_some()
        {
            accu.push(file);
        }
    }
    Ok(accu)
}
