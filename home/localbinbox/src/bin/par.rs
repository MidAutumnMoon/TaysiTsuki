use std::env::current_dir;
use std::env::set_current_dir;
use std::io::BufRead as _;
use std::io::BufReader;
use std::path::Path;
use std::path::PathBuf;
use std::process::Command;
use std::process::Stdio;

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
use tap::Pipe as _;
use tap::Tap as _;

const CFG_PAR2: Option<&str> = option_env!("CFG_PAR2");

fn main() -> Result<()> {
    let paths = {
        let args = std::env::args().skip(1).collect_vec();
        let cwd = current_dir()?;
        let inputs = if args.is_empty() {
            ceprintln!(Yellow, "No files, read current dir");
            collect_read_dir(&cwd)?
        } else {
            args.into_iter()
                .map(|p| {
                    let p = Path::new(&p);
                    if p.is_absolute() {
                        p.to_owned()
                    } else {
                        cwd.join(p)
                    }
                })
                .collect_vec()
        };
        ensure!(
            inputs.iter().all(|p| p.exists()),
            "Some path does not exits or not accessible"
        );
        ensure!(
            inputs.iter().all(|p| p.is_absolute()),
            "[BUG] Paths must all be absolute"
        );
        inputs
    };

    for p in paths {
        par_sum(&p).context("Error while processing path")?;
    }

    Ok(())
}

/// Generate par2archive and checksum the generated files.
#[expect(clippy::too_many_lines)]
fn par_sum(path: &Path) -> Result<()> {
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
            .select(|p| p.is_file())
            .collect(),
        PathType::File => vec![path.to_owned()],
    };

    ensure!(
        src_files.iter().all(|f| f.is_absolute()),
        "[BUG] Some paths are not absolute"
    );

    ensure!(
        src_files.iter().all(|f| f.is_file()),
        "[BUG] Some paths are not files"
    );

    for file in &src_files {
        let parent = parent_of(file)?;
        let basename = basename_of(file)?;
        ensure!(!basename.is_empty());

        ceprintln!(Blue, "Par2archive file {basename}");

        // Set cwd so that the files can be referred to with
        // just basename, and it also makes generated
        // par2archive path independent.
        set_current_dir(parent)
            .context("Failed to set working directory")?;

        let status = Command::new(CFG_PAR2.unwrap_or("par2"))
            .arg("create")
            // 1 volume file
            .arg("-n1")
            // 5% of redundancy
            .arg("-r5")
            .arg("-q")
            // N.B. chdir above
            .arg(basename)
            .spawn()
            .context("Failed to spawn par2")?
            .wait()?;

        ensure!(status.success(), "Par2 exited with error");

        // Par2 index file is not essential to recovery
        // so delete it reduce the file count
        let par2_index_name = format!("{basename}.par2");
        std::fs::remove_file(Path::new(&par2_index_name))
            .context("Failed to remove par2 index file")?;

        let par2_volume = match &*par2_volumes(parent, basename)? {
            [v] => v.clone(),
            [_v, ..] => bail!("[BUG] Found multiple par2 volume"),
            [] => bail!("[BUG] No par2 volume found"),
        };

        ensure!(par2_volume.is_absolute());

        // N.B. chdir into parent
        std::fs::rename(&par2_volume, parent.join(par2_index_name))
            .context("Failed to rename par2 index file")?;
    }

    ceprintln!(Blue, "Checksum for {}", basename_of(path)?);

    let checksum_file = match path_type {
        PathType::Dir => {
            set_current_dir(path)?;
            path.join("__directory.sha256sum")
        }
        PathType::File => {
            let parent = parent_of(path)?;
            let basename = basename_of(path)?;
            set_current_dir(parent)?;
            parent.join(format!("{basename}.sha256sum"))
        }
    };

    let checksum = {
        // Duplicate src_files and add `.par2` to each one.
        let src_files = {
            let mut src_files_par2 = vec![];
            for f in src_files.clone() {
                let basename = basename_of(&f)?;
                let par2 = format!("{basename}.par2");
                f.tap_mut(|f| f.set_file_name(par2))
                    .pipe(|v| src_files_par2.push(v));
            }
            src_files.tap_mut(|s| s.append(&mut src_files_par2))
        };

        let basenames = src_files
            .into_iter()
            .map(|v| basename_of(&v).map(str::to_owned))
            .collect::<Result<Vec<_>>>()?
            .into_iter()
            .sorted()
            .collect::<Vec<_>>();

        let mut checksum = String::with_capacity(4 * 1000);

        // N.B. chdir above.
        // Paths in the checksum file will be relative.
        // Maybe implement it in Rust would be more performant...
        let mut child = Command::new("sha256sum")
            .arg("--")
            .args(&basenames)
            .stdout(Stdio::piped())
            .spawn()
            .context("Failed to spawn sha256sum")?;

        let stdout = child.stdout.take().ok_or_else(|| {
            anyhow::anyhow!("[BUG] Can not take child stdout")
        })?;

        for line in BufReader::new(stdout).lines() {
            let line = format!("{}\n", line?);
            checksum.push_str(&line);
            eprint!("{line}");
        }

        ensure!(child.wait()?.success(), "sha256sum exited with error");

        checksum
    };

    std::fs::write(&checksum_file, checksum)?;

    Ok(())
}

#[inline]
fn basename_of(path: &Path) -> Result<&str> {
    if let Some(b) = path.file_name()
        && let Some(b) = b.to_str()
    {
        Ok(b)
    } else {
        bail!("Path {} does not have a valid basename", path.display())
    }
}

#[inline]
fn parent_of(path: &Path) -> Result<&Path> {
    if let Some(d) = path.parent() {
        Ok(d)
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
