use std::env;
use std::env::current_dir;
use std::ffi::OsStr;
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
    let cwd = current_dir().context("Failed to get CWD")?;
    let args = env::args().skip(1).collect_vec();

    let paths = if args.is_empty() {
        ceprintln!(Yellow, "No files, read current dir");
        collect_read_dir(&cwd)?
    } else {
        args.iter()
            .map(|arg| {
                let path = Path::new(arg);
                if path.is_absolute() {
                    path.to_owned()
                } else {
                    cwd.join(path)
                }
            })
            .collect_vec()
    };

    // Parse every input before generating anything, so a bad path
    // aborts the run before a single volume exists.
    let inputs = paths
        .into_iter()
        .map(Input::parse)
        .collect::<Result<Vec<_>>>()?;

    for input in &inputs {
        par2(input).with_context(|| {
            format!("Error while processing {}", input.path().display())
        })?;
    }

    Ok(())
}

/// A validated par2 input.
enum Input {
    /// The file itself gets one recovery volume.
    File(PathBuf),
    /// Every immediate regular file gets one recovery volume.
    Dir(PathBuf),
}

impl Input {
    /// Classify an existing, absolute path. Symlinks are followed,
    /// not rejected — rare for this tool's inputs.
    fn parse(path: PathBuf) -> Result<Self> {
        ensure!(path.is_absolute(), "{} is not absolute", path.display());
        if path.is_file() {
            ceprintln!(Yellow, "File mode");
            Ok(Self::File(path))
        } else if path.is_dir() {
            ceprintln!(Yellow, "Directory mode");
            Ok(Self::Dir(path))
        } else {
            bail!("{} is neither file nor dir", path.display())
        }
    }

    fn path(&self) -> &Path {
        match self {
            Self::File(path) | Self::Dir(path) => path,
        }
    }

    /// The files that each get a `<name>.par2` recovery volume.
    fn src_files(&self) -> Result<Vec<SrcFile>> {
        match self {
            // Explicit input is always protected, even a `.par2` —
            // the user named it.
            Self::File(path) => Ok(vec![SrcFile::new(path)?]),
            // Non-recursive: immediate regular files only. This
            // tool's own `*.par2` outputs are skipped, so reruns
            // don't par2 the par2 files.
            Self::Dir(dir) => collect_read_dir(dir)?
                .into_iter()
                .select(|path| path.is_file() && !is_par2_name(path))
                .map(|path| SrcFile::new(&path))
                .collect(),
        }
    }
}

/// A regular file to protect, addressed the way par2 handles it:
/// by basename, inside its own parent directory.
struct SrcFile {
    parent: PathBuf,
    name: String,
}

impl SrcFile {
    /// Split an absolute regular file into parent + UTF-8 basename.
    /// That precondition is established by [`Input::src_files`].
    fn new(path: &Path) -> Result<Self> {
        let name = path
            .file_name()
            .and_then(OsStr::to_str)
            .with_context(|| {
                format!("{} has no UTF-8 basename", path.display())
            })?
            .to_owned();
        let parent = path
            .parent()
            .with_context(|| format!("{} has no parent", path.display()))?
            .to_owned();
        Ok(Self { parent, name })
    }
}

/// Generate one `<name>.par2` recovery volume per source file.
fn par2(input: &Input) -> Result<()> {
    let src_files = input.src_files()?;
    ceprintln!(Yellow, "Par2archive for {}", input.path().display());
    for src in &src_files {
        create_par2_volume(src)?;
    }
    Ok(())
}

fn create_par2_volume(src: &SrcFile) -> Result<()> {
    let SrcFile { parent, name } = src;
    ceprintln!(Blue, "Par2archive file {name}");
    let index_name = format!("{name}.par2");
    let index = parent.join(&index_name);

    // Clear old outputs first: par2 refuses to create over an
    // existing `<name>.par2`, and a stale volume (its `volNNN+MMM`
    // suffix tracks the source size) would make the scan below find
    // two. Everything removed is regenerable from the source.
    if index.exists() {
        fs::remove_file(&index).with_context(|| {
            format!("Failed to remove old {index_name}")
        })?;
    }
    for stale in volume_files(parent, name)? {
        fs::remove_file(&stale).with_context(|| {
            format!("Failed to remove stale {}", stale.display())
        })?;
    }

    runner(
        par2_cmd_template("create", parent)
            // one volume file
            .arg("-n1")
            // 5% redundancy
            .arg("-r5")
            .arg("--")
            .arg(name),
        "par2 create",
    )?;

    // par2 wrote the index `<name>.par2` (it carries no recovery
    // data) and one volume. Keep only the volume: a single rename
    // over the index, which it replaces atomically.
    let volumes = volume_files(parent, name)?;
    let volume = match &*volumes {
        [volume] => volume,
        [_, ..] => bail!("[BUG] Expected exactly one par2 volume"),
        [] => bail!("[BUG] No par2 volume found"),
    };
    fs::rename(volume, &index)
        .with_context(|| format!("Failed to rename volume for {name}"))?;

    // Verify while the source still exists: a failure now is
    // recoverable by rerunning — once the source is gone, a bad
    // volume only surfaces at restore time.
    runner(
        par2_cmd_template("verify", parent)
            .arg("--")
            .arg(&index_name),
        "par2 verify",
    )?;

    Ok(())
}

fn par2_cmd_template(subcommand: &str, parent: &Path) -> Command {
    let mut cmd = Command::new(CFG_PAR2.unwrap_or("par2"));
    cmd.current_dir(parent).arg(subcommand).arg("-q");
    cmd
}

/// Run `cmd` and require a successful exit.
fn runner(cmd: &mut Command, what: &str) -> Result<()> {
    let status = cmd
        .spawn()
        .with_context(|| format!("Failed to spawn {what}"))?
        .wait()?;
    ensure!(status.success(), "{what} exited with error");
    Ok(())
}

/// Volume files for `name` in `parent`: `<name>.volNNN+MMM.par2`,
/// where par2 picks `NNN`/`MMM` from the source size.
fn volume_files(parent: &Path, name: &str) -> Result<Vec<PathBuf>> {
    let prefix = format!("{name}.vol");
    Ok(collect_read_dir(parent)?
        .into_iter()
        .filter(|file| is_volume_name(file.file_name(), &prefix))
        .collect())
}

/// `<prefix>NNN+MMM.par2` — par2's volume naming: `NNN` is the
/// first recovery block, `MMM` the slice count. The digit check
/// keeps lookalikes (`name.volume2.par2`) out: everything matched
/// here is deletable.
fn is_volume_name(file_name: Option<&OsStr>, prefix: &str) -> bool {
    file_name
        .and_then(OsStr::to_str)
        .and_then(|basename| basename.strip_circumfix(prefix, ".par2"))
        .is_some_and(|blocks| {
            blocks.split_once('+').is_some_and(|(first, count)| {
                !first.is_empty()
                    && first.bytes().all(|byte| byte.is_ascii_digit())
                    && !count.is_empty()
                    && count.bytes().all(|byte| byte.is_ascii_digit())
            })
        })
}

fn is_par2_name(path: &Path) -> bool {
    path.extension().is_some_and(|ext| ext == "par2")
}
