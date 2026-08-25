//! Transactional on-disk checkpoints of a live overlay view.
//!
//! A transfer is built in a sibling staging directory. Only a complete,
//! fsynced tree carrying an internal versioned marker may replace the current
//! mirror. Interrupted transfers never mutate the last committed mirror.

use std::fs;
use std::io::ErrorKind;
use std::io::Write as _;
use std::path::Path;
use std::process::Command;
use std::process::Output;
use std::time::SystemTime;

use anyhow::Context as _;
use anyhow::Result;
use anyhow::bail;
use rustix::fs::CWD;
use rustix::fs::RenameFlags;
use rustix::fs::renameat_with;
use tracing::debug;
use tracing::warn;

use crate::exec;
use crate::paths::ProfilePaths;

/// Reserved inside committed mirrors. The version is part of the format.
pub const MARKER_NAME: &str = ".psd-checkpoint-v1";

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Outcome {
    Committed,
    /// A source entry vanished while the live application was mutating it.
    SourceChanged,
}

/// Build and atomically publish one checkpoint.
pub fn run(paths: &ProfilePaths) -> Result<Outcome> {
    run_with(paths, exec::output)
}

fn run_with(
    paths: &ProfilePaths,
    execute: impl FnOnce(&mut Command) -> Result<Output>,
) -> Result<Outcome> {
    prepare_staging(paths)?;
    let outcome = match rsync_to_staging(paths, execute) {
        Ok(outcome) => outcome,
        Err(error) => return cleanup_failed_build(paths, error),
    };
    if outcome == Outcome::SourceChanged {
        discard_staging(paths)?;
        return Ok(outcome);
    }
    if let Err(error) = write_internal_marker(&paths.back_ovfs_stage) {
        return cleanup_failed_build(paths, error);
    }
    commit_staging(paths)?;
    Ok(Outcome::Committed)
}

fn cleanup_failed_build(
    paths: &ProfilePaths,
    error: anyhow::Error,
) -> Result<Outcome> {
    match discard_staging(paths) {
        Ok(()) => Err(error),
        Err(cleanup_error) => Err(error.context(format!(
            "also failed to discard incomplete checkpoint: {cleanup_error:#}"
        ))),
    }
}

fn prepare_staging(paths: &ProfilePaths) -> Result<()> {
    let _ = plain_directory_exists(&paths.back_ovfs)?;
    discard_staging(paths)?;
    fs::create_dir(&paths.back_ovfs_stage).with_context(|| {
        format!("mkdir {}", paths.back_ovfs_stage.display())
    })
}

/// Transfer into an empty sibling. `--link-dest` reuses unchanged files
/// without allowing an interrupted run to mutate the committed mirror.
fn rsync_to_staging(
    paths: &ProfilePaths,
    execute: impl FnOnce(&mut Command) -> Result<Output>,
) -> Result<Outcome> {
    let mut command = Command::new("rsync");
    command.args([
        "-aX",
        "--checksum",
        "--checksum-choice=xxh128",
        "--fsync",
    ]);
    if plain_directory_exists(&paths.back_ovfs)? {
        command.arg(format!("--link-dest={}", paths.back_ovfs.display()));
    }
    command
        .arg(format!("{}/", paths.dir.display()))
        .arg(&paths.back_ovfs_stage);
    debug!(cmd = ?command, "rsync checkpoint");
    let output = execute(&mut command).with_context(|| {
        format!(
            "rsync {} -> {}",
            paths.dir.display(),
            paths.back_ovfs_stage.display()
        )
    })?;
    match accepted_rsync_outcome(output.status.code()) {
        Some(Outcome::Committed) => Ok(Outcome::Committed),
        Some(Outcome::SourceChanged) => {
            warn!(
                src = %paths.dir.display(),
                staging = %paths.back_ovfs_stage.display(),
                detail = %String::from_utf8_lossy(&output.stderr).trim(),
                "rsync source changed; discarding incomplete checkpoint"
            );
            Ok(Outcome::SourceChanged)
        }
        None => bail!(
            "rsync {} -> {} failed (exit {}): {}",
            paths.dir.display(),
            paths.back_ovfs_stage.display(),
            output.status.code().unwrap_or(-1),
            String::from_utf8_lossy(&output.stderr).trim()
        ),
    }
}

fn commit_staging(paths: &ProfilePaths) -> Result<()> {
    fsync_dir(&paths.back_ovfs_stage)?;
    if plain_directory_exists(&paths.back_ovfs)? {
        renameat_with(
            CWD,
            &paths.back_ovfs_stage,
            CWD,
            &paths.back_ovfs,
            RenameFlags::EXCHANGE,
        )
        .with_context(|| {
            format!(
                "atomically exchange {} and {}",
                paths.back_ovfs_stage.display(),
                paths.back_ovfs.display()
            )
        })?;
    } else {
        fs::rename(&paths.back_ovfs_stage, &paths.back_ovfs)
            .with_context(|| {
                format!(
                    "commit {} -> {}",
                    paths.back_ovfs_stage.display(),
                    paths.back_ovfs.display()
                )
            })?;
    }
    fsync_parent(&paths.back_ovfs)?;

    // The previous implementation used a sidecar marker. A completed
    // internal marker supersedes it; cleanup failure cannot invalidate data.
    if let Err(error) = remove_legacy_marker(paths) {
        warn!(
            marker = %paths.legacy_back_ovfs_committed.display(),
            error = %format_args!("{error:#}"),
            "checkpoint committed but legacy marker could not be removed"
        );
    }

    // After an exchange the staging name contains the previous complete
    // generation. Failure to reclaim it does not invalidate the commit.
    if let Err(error) = discard_staging(paths) {
        warn!(
            staging = %paths.back_ovfs_stage.display(),
            error = %format_args!("{error:#}"),
            "checkpoint committed but previous generation could not be removed"
        );
    }
    Ok(())
}

fn write_internal_marker(directory: &Path) -> Result<()> {
    let marker = marker_path(directory);
    remove_marker(directory)?;
    let mut file = fs::OpenOptions::new()
        .write(true)
        .create_new(true)
        .open(&marker)
        .with_context(|| format!("create {}", marker.display()))?;
    file.write_all(b"psd-rs checkpoint format 1\n")
        .with_context(|| format!("write {}", marker.display()))?;
    file.sync_all()
        .with_context(|| format!("fsync {}", marker.display()))?;
    Ok(())
}

pub fn is_committed(paths: &ProfilePaths) -> Result<bool> {
    if marker_modified(&paths.back_ovfs)?.is_some() {
        return Ok(true);
    }
    legacy_marker_modified(paths).map(|modified| modified.is_some())
}

pub fn committed_at(paths: &ProfilePaths) -> Result<Option<SystemTime>> {
    if let Some(modified) = marker_modified(&paths.back_ovfs)? {
        return Ok(Some(modified));
    }
    legacy_marker_modified(paths)
}

fn marker_modified(directory: &Path) -> Result<Option<SystemTime>> {
    managed_file_modified(&marker_path(directory), "checkpoint marker")
}

fn legacy_marker_modified(
    paths: &ProfilePaths,
) -> Result<Option<SystemTime>> {
    managed_file_modified(
        &paths.legacy_back_ovfs_committed,
        "legacy checkpoint marker",
    )
}

fn managed_file_modified(
    path: &Path,
    description: &str,
) -> Result<Option<SystemTime>> {
    match fs::symlink_metadata(path) {
        Ok(metadata) if metadata.is_file() => metadata
            .modified()
            .map(Some)
            .with_context(|| format!("read mtime for {}", path.display())),
        Ok(_) => bail!("{} is not psd's {description}", path.display()),
        Err(error) if error.kind() == ErrorKind::NotFound => Ok(None),
        Err(error) => Err(error)
            .with_context(|| format!("inspect {}", path.display())),
    }
}

pub fn remove_marker(directory: &Path) -> Result<()> {
    remove_managed_file(&marker_path(directory), "checkpoint marker")
}

pub fn remove_legacy_marker(paths: &ProfilePaths) -> Result<()> {
    remove_managed_file(
        &paths.legacy_back_ovfs_committed,
        "legacy checkpoint marker",
    )
}

fn marker_path(directory: &Path) -> std::path::PathBuf {
    directory.join(MARKER_NAME)
}

pub fn discard_staging(paths: &ProfilePaths) -> Result<()> {
    remove_managed_directory(&paths.back_ovfs_stage)
}

fn remove_managed_directory(path: &Path) -> Result<()> {
    match fs::symlink_metadata(path) {
        Ok(metadata) if metadata.is_dir() => fs::remove_dir_all(path)
            .with_context(|| format!("remove {}", path.display())),
        Ok(_) => {
            bail!("{} is not psd's staging directory", path.display())
        }
        Err(error) if error.kind() == ErrorKind::NotFound => Ok(()),
        Err(error) => Err(error)
            .with_context(|| format!("inspect {}", path.display())),
    }
}

fn remove_managed_file(path: &Path, description: &str) -> Result<()> {
    match fs::symlink_metadata(path) {
        Ok(metadata) if metadata.is_file() => fs::remove_file(path)
            .with_context(|| format!("remove {}", path.display())),
        Ok(_) => bail!("{} is not psd's {description}", path.display()),
        Err(error) if error.kind() == ErrorKind::NotFound => Ok(()),
        Err(error) => Err(error)
            .with_context(|| format!("inspect {}", path.display())),
    }
}

fn plain_directory_exists(path: &Path) -> Result<bool> {
    match fs::symlink_metadata(path) {
        Ok(metadata) if metadata.is_dir() => Ok(true),
        Ok(_) => bail!("{} is not a plain directory", path.display()),
        Err(error) if error.kind() == ErrorKind::NotFound => Ok(false),
        Err(error) => Err(error)
            .with_context(|| format!("inspect {}", path.display())),
    }
}

fn fsync_parent(path: &Path) -> Result<()> {
    let parent = path.parent().with_context(|| {
        format!("{} has no parent directory", path.display())
    })?;
    fsync_dir(parent)
}

fn fsync_dir(path: &Path) -> Result<()> {
    let file = fs::File::open(path)
        .with_context(|| format!("open {}", path.display()))?;
    match file.sync_all() {
        Ok(()) => Ok(()),
        // Some filesystems reject fsync on directories.
        Err(error) if error.kind() == ErrorKind::InvalidInput => {
            warn!(
                dir = %path.display(),
                "filesystem does not support syncing directories"
            );
            Ok(())
        }
        Err(error) => {
            Err(error).with_context(|| format!("fsync {}", path.display()))
        }
    }
}

fn accepted_rsync_outcome(code: Option<i32>) -> Option<Outcome> {
    match code {
        Some(0) => Some(Outcome::Committed),
        Some(24) => Some(Outcome::SourceChanged),
        Some(_) | None => None,
    }
}

#[cfg(test)]
#[expect(clippy::unwrap_used, reason = "Tests")]
mod tests {
    use std::fs::create_dir_all;
    use std::fs::read;
    use std::fs::write;
    use std::os::unix::process::ExitStatusExt as _;
    use std::process::ExitStatus;

    use super::*;

    use tempfile::tempdir;

    use crate::apps::AppKind;
    use crate::apps::AppProfile;

    fn make_paths(root: &Path) -> ProfilePaths {
        let profile = AppProfile {
            kind: AppKind::Firefox,
            user: "user".to_owned(),
            path: root.join("profile"),
            suffix: "profile".to_owned(),
        };
        ProfilePaths::new(&profile, root)
    }

    fn output(code: i32, stderr: &str) -> Output {
        Output {
            status: ExitStatus::from_raw(code << 8),
            stdout: Vec::new(),
            stderr: stderr.as_bytes().to_vec(),
        }
    }

    #[test]
    fn source_churn_discards_staging_and_preserves_committed_mirror() {
        let temp = tempdir().unwrap();
        let paths = make_paths(temp.path());
        create_dir_all(&paths.dir).unwrap();
        create_dir_all(&paths.back_ovfs).unwrap();
        write(paths.back_ovfs.join("data"), b"old").unwrap();

        let outcome = run_with(&paths, |command| {
            let arguments = command
                .get_args()
                .map(|argument| argument.to_string_lossy().into_owned())
                .collect::<Vec<_>>();
            assert!(
                arguments.iter().any(|argument| argument == "--checksum")
            );
            assert!(
                arguments
                    .iter()
                    .any(|argument| argument.starts_with("--link-dest="))
            );
            write(paths.back_ovfs_stage.join("data"), b"partial").unwrap();
            Ok(output(24, "file vanished"))
        })
        .unwrap();

        assert_eq!(outcome, Outcome::SourceChanged);
        assert_eq!(read(paths.back_ovfs.join("data")).unwrap(), b"old");
        assert!(!paths.back_ovfs_stage.exists());
    }

    #[test]
    fn commit_moves_data_and_marker_as_one_tree() {
        let temp = tempdir().unwrap();
        let paths = make_paths(temp.path());
        create_dir_all(&paths.dir).unwrap();
        create_dir_all(&paths.back_ovfs).unwrap();
        write(paths.back_ovfs.join("data"), b"old").unwrap();
        write(&paths.legacy_back_ovfs_committed, b"legacy").unwrap();

        let outcome = run_with(&paths, |_| {
            write(paths.back_ovfs_stage.join("data"), b"new").unwrap();
            Ok(output(0, ""))
        })
        .unwrap();

        assert_eq!(outcome, Outcome::Committed);
        assert_eq!(read(paths.back_ovfs.join("data")).unwrap(), b"new");
        assert!(marker_path(&paths.back_ovfs).is_file());
        assert!(!paths.back_ovfs_stage.exists());
        assert!(!paths.legacy_back_ovfs_committed.exists());
    }

    #[test]
    fn ordinary_rsync_error_discards_staging_and_preserves_commit() {
        let temp = tempdir().unwrap();
        let paths = make_paths(temp.path());
        create_dir_all(&paths.dir).unwrap();
        create_dir_all(&paths.back_ovfs).unwrap();
        write(paths.back_ovfs.join("data"), b"committed").unwrap();
        write(marker_path(&paths.back_ovfs), b"format 1").unwrap();

        let error = run_with(&paths, |_| {
            write(paths.back_ovfs_stage.join("data"), b"partial").unwrap();
            Ok(output(23, "partial transfer"))
        })
        .unwrap_err();

        assert!(error.to_string().contains("exit 23"));
        assert_eq!(
            read(paths.back_ovfs.join("data")).unwrap(),
            b"committed"
        );
        assert!(marker_path(&paths.back_ovfs).is_file());
        assert!(!paths.back_ovfs_stage.exists());
    }

    #[test]
    fn first_checkpoint_publishes_without_a_previous_mirror() {
        let temp = tempdir().unwrap();
        let paths = make_paths(temp.path());
        create_dir_all(&paths.dir).unwrap();

        let outcome = run_with(&paths, |_| {
            write(paths.back_ovfs_stage.join("data"), b"first").unwrap();
            Ok(output(0, ""))
        })
        .unwrap();

        assert_eq!(outcome, Outcome::Committed);
        assert_eq!(read(paths.back_ovfs.join("data")).unwrap(), b"first");
        assert!(marker_path(&paths.back_ovfs).is_file());
        assert!(committed_at(&paths).unwrap().is_some());
        assert!(!paths.back_ovfs_stage.exists());
    }
}
