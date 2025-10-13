use std::env::current_dir;
use std::path::Path;
use std::path::PathBuf;
use std::process::Command;

use anyhow::Context;
use anyhow::Result;
use anyhow::ensure;
use ino_color::ceprintln;
use ino_color::fg::Yellow;
use ino_iter::InoIter;
use itertools::Itertools;
use localbinbox::collect_read_dir;

const CFG_7Z_PATH: Option<&str> = option_env!("CFG_7Z_PATH");
const BACKUP_DIR_NAME: &str = ".backup";

/// 7z wrapper
#[derive(clap::Parser)]
#[derive(Debug)]
struct CliOpts {
    /// Disable moving the source directory to back up dir
    /// and par2archive of the created archive.
    #[clap(long, short = 'N')]
    #[clap(default_value_t = false)]
    no_backup_no_par: bool,

    /// Don't remove source directory after archiving. Only has affect
    /// when `-N` is supplied.
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
        no_backup_no_par,
        keep_source,
        inputs,
    } = <CliOpts as clap::Parser>::parse();

    let cwd = current_dir().context("Failed to get CWD")?;
    let backup_dir = cwd.join(BACKUP_DIR_NAME);

    let dirs_to_archive = {
        let paths = if let Some(inputs) = inputs {
            let inputs =
                inputs.into_iter().map(|i| cwd.join(i)).collect_vec();
            ensure!(
                inputs.iter().all(|p| p.is_dir()),
                "Inputs must all be directories"
            );
            inputs
        } else {
            ceprintln!(Yellow, "No inputs, glob CWD for directories");
            collect_read_dir(&cwd)?
                .into_iter()
                // Remove hidden files from auto found results
                // Hidden dirs from manual inputs are not filtered though
                .reject(|p| {
                    p.file_name()
                        .and_then(|n| n.to_str())
                        .is_some_and(|n| n.starts_with('.'))
                })
                .collect()
        };
        ensure!(
            paths.iter().all(|p| p.is_absolute()),
            "[BUG] Some paths are not absolute"
        );
        paths
            .into_iter()
            // Only archive dirs
            .select(|p| p.is_dir())
            // Skip `.backup` dir
            .reject(|p| {
                p.file_name().is_some_and(|n| n == BACKUP_DIR_NAME)
            })
            .collect_vec()
    };

    dbg!(&dirs_to_archive);

    if !no_backup_no_par {
        std::fs::create_dir_all(&backup_dir)
            .context("Failed to create backup dir")?;
    }

    for dir in dirs_to_archive {
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
        archive_using_7z(&dir, &archive)
            .context("Failed to archive dir using 7z")?;

        if no_backup_no_par {
            if !keep_source {
                ceprintln!(Yellow, "Remove source dir");
                std::fs::remove_dir_all(&dir)
                    .context("Failed to remove source dir")?;
            }
        } else {
            ceprintln!(Yellow, ",par {}", basename.display());
            par(&archive).context("Failed to ,par2")?;

            ceprintln!(Yellow, "Move {} to backup", basename.display());
            // TODO: not use basename, use full path instead?
            std::fs::rename(&dir, backup_dir.join(basename))
                .context("Failed to backup original directory")?;
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
        .args(["-slp", "-ssp"])
        // 7z archive
        .arg("-t7z")
        // 7z lzma2
        .arg("-m0=lzma2")
        // level of compression
        .args(["-mx9", "-myx9"])
        // 15GiB solid block
        .arg("-ms=16G")
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

fn par(archive: &Path) -> Result<()> {
    let status = Command::new(",par")
        .arg(archive)
        .spawn()
        .context("Failed to spawn ,par")?
        .wait()?;
    ensure!(status.success(), ",par exited with error");
    Ok(())
}
