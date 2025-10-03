use std::path::PathBuf;
use std::process::Command;
use std::str::FromStr;
use std::sync::LazyLock;

use anyhow::Context;
use anyhow::Result;
use anyhow::bail;
use anyhow::ensure;
use strum::EnumString;

// TODO: avoid hardcoded name
const REMOTE: &str = "Box";

static POOL: LazyLock<PathBuf> =
    LazyLock::new(|| PathBuf::from("/srv/pool"));

#[rustfmt::skip]
const EXCLUDE_PATTERN: &[&str] = &[
    "/.zfs/",
    "/.recycle/",
    "/__Income__/"
];

#[derive(Debug)]
#[derive(EnumString)]
#[strum(serialize_all = "lowercase")]
enum SyncDirection {
    Up,
    Down,
}

fn main() -> Result<()> {
    let direction = match &std::env::args().collect::<Vec<_>>()[..] {
        [_exe] => bail!("sync up or down"),
        [_exe, arg] => SyncDirection::from_str(arg)
            .context("Failed to parse argument")?,
        _ => bail!("too many arguments"),
    };

    ensure! { POOL.is_dir(),
        "{} is not a directory",
        POOL.display()
    };

    let exclude_opts: Vec<_> = EXCLUDE_PATTERN
        .iter()
        .flat_map(|path| ["--exclude", path])
        .collect();

    let sync_opts: [String; 2] = {
        let remote = format!("{REMOTE}:");
        let pool = POOL.to_str().unwrap().to_owned();
        match direction {
            SyncDirection::Up => [pool, remote],
            SyncDirection::Down => [remote, pool],
        }
    };

    Command::new(",rclone")
        .arg("sync")
        .args(&exclude_opts)
        .args(&sync_opts)
        .spawn()
        .context("Failed to spawn ,rclone")?
        .wait()
        .map(|_| ())
        .map_err(Into::into)
}
