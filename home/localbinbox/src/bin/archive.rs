use std::env::current_dir;
use std::fs::remove_dir_all;
use std::path::Path;
use std::path::PathBuf;
use std::process::Command;

use anyhow::Context as _;
use anyhow::Result;
use anyhow::ensure;
use ino_color::ceprintln;
use ino_color::fg::Yellow;
use ino_iter::InoIter as _;
use itertools::Itertools as _;
use localbinbox::collect_read_dir;

const CFG_7Z_PATH: Option<&str> = option_env!("CFG_7Z_PATH");
const BACKUP_DIR_NAME: &str = ".backup";

/// 7z wrapper.
#[derive(clap::Parser)]
#[derive(Debug)]
struct CliOpts {
    /// Disable generating par2archive for the created archive.
    #[clap(long, short = 'N')]
    #[clap(default_value_t = false)]
    no_par: bool,

    /// Don't remove source directories after archiving.
    #[clap(long, short = 'K')]
    #[clap(default_value_t = false)]
    keep_source: bool,

    /// Directories to archive. If not supplied, glob current directory
    /// automatically for directories.
    #[clap()]
    inputs: Option<Vec<PathBuf>>,
}

fn main() -> Result<()> {
    let CliOpts {
        no_par,
        keep_source,
        inputs,
    } = <CliOpts as clap::Parser>::parse();

    let cwd = current_dir().context("Failed to get CWD")?;

    let dirs_to_archive = {
        let paths = if let Some(inputs) = inputs {
            let inputs =
                inputs.into_iter().map(|i| cwd.join(i)).collect_vec();
            ensure!(
                inputs.iter().all(|path| path.is_dir()),
                "Inputs must all be directories"
            );
            inputs
        } else {
            ceprintln!(Yellow, "No inputs, glob CWD for directories");
            collect_read_dir(&cwd)?
                .into_iter()
                // Remove hidden files from auto found results
                // Hidden dirs from manual inputs are not filtered though
                .reject(|path| {
                    path.file_name()
                        .and_then(|name| name.to_str())
                        .is_some_and(|name| name.starts_with('.'))
                })
                .collect()
        };
        ensure!(
            paths.iter().all(|path| path.is_absolute()),
            "[BUG] Some paths are not absolute"
        );
        paths
            .into_iter()
            // Only archive dirs
            .select(|path| path.is_dir())
            // Skip `.backup` dir
            .reject(|path| {
                path.file_name().is_some_and(|n| n == BACKUP_DIR_NAME)
            })
            .collect_vec()
    };

    for dir in &dirs_to_archive {
        // Paths are absolute, they can't not have a basename or parent.
        let basename = dir.file_name().ok_or_else(|| {
            anyhow::anyhow!(
                "[BUG] Directory {} has no valid basename",
                dir.display()
            )
        })?;
        let parent = dir.parent().ok_or_else(|| {
            anyhow::anyhow!(
                "[BUG] Directory {} has no valid parent name",
                dir.display()
            )
        })?;
        let archive = parent.join(format!(
            "{}.7z",
            basename.to_str().ok_or_else(|| anyhow::anyhow!(
                "Failed to convert OsStr to str"
            ))?
        ));

        ceprintln!(Yellow, "Archiving {}", basename.display());
        archive_using_7z(dir, &archive)
            .context("Failed to archive dir using 7z")?;

        ceprintln!(Yellow, "Testing {}", archive.display());
        test_archive(&archive).context("Failed to test archive")?;

        if no_par {
            ceprintln!(Yellow, "Skipping par2archive");
        } else {
            ceprintln!(Yellow, ",par {}", archive.display());
            par(&archive).context("Failed to ,par2")?;
        }
    }

    // Only delete sources after every archive has passed its test.
    if !keep_source {
        for dir in &dirs_to_archive {
            ceprintln!(Yellow, "Deleting source dir {}", dir.display());
            remove_dir_all(dir).with_context(|| {
                format!("Failed to remove source dir {}", dir.display())
            })?;
        }
    }

    Ok(())
}

fn archive_using_7z(src: &Path, dst: &Path) -> Result<()> {
    // 7z manual somehow is really tedious to find,
    // <https://7zip.bugaco.com/7zip/MANUAL/cmdline/syntax.htm> is a more
    // complete manual
    let status = Command::new(CFG_7Z_PATH.unwrap_or("7zz"))
        // a : archive
        .arg("a")
        // Prevent changing source file' last access time.
        .arg("-ssp")
        // Stop archive if can't open source file.
        .arg("-sse")
        // Disable wildcard
        .arg("-spd")
        // it's 7z archive
        .arg("-t7z")
        // 7z lzma2
        .arg("-m0=lzma2")
        // level of compression (x) and analysis (yx)
        .args(["-mx9", "-myx9"])
        // Threads, less threads can yield better compression ratio.
        .arg("-mmt=2")
        // 16GiB solid block
        .arg("-ms=16G")
        // Sort files in solid archive
        .arg("-mqs=on")
        // dictionary size
        .arg("-md=3840M")
        .arg("--")
        .arg(dst)
        .arg(src)
        .spawn()
        .context("Failed to spawn 7z")?
        .wait()
        .context("Failed to wait for 7z")?;
    ensure!(status.success(), "7z exited with error");
    Ok(())
}

fn test_archive(archive: &Path) -> Result<()> {
    let status = Command::new(CFG_7Z_PATH.unwrap_or("7zz"))
        // t : test archive integrity
        .arg("t")
        .arg("--")
        .arg(archive)
        .spawn()
        .context("Failed to spawn 7z")?
        .wait()
        .context("Failed to wait for 7z")?;
    ensure!(status.success(), "7z test exited with error");
    Ok(())
}

fn par(archive: &Path) -> Result<()> {
    let status = Command::new(",par")
        .arg(archive)
        .spawn()
        .context("Failed to spawn ,par")?
        .wait()?;
    ensure!(status.success(), ",par exited with error");
    Ok(())
}
