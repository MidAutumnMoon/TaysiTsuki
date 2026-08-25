use std::path::PathBuf;
use std::process::Command;
use std::str::FromStr as _;
use std::sync::LazyLock;

use anyhow::Context as _;
use anyhow::Result;
use anyhow::bail;
use anyhow::ensure;
use ino_color::ceprintln;
use ino_color::fg::Blue;
use ino_color::fg::Yellow;
use strum::EnumString;

// TODO: avoid hardcoded name
const REMOTE: &str = "Box";
const SUBDIR: &str = "Pool";

static LOCAL_DIR: LazyLock<PathBuf> =
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
    let args: Vec<String> = std::env::args().collect();
    let (direction, extra_args) = match args.as_slice() {
        [_exe, arg, rem @ ..] => (
            SyncDirection::from_str(arg)
                .context("Failed to parse argument")?,
            rem,
        ),
        _ => bail!("sync up or down"),
    };

    ensure! { LOCAL_DIR.is_dir(),
        r#"Expect "{}" to be a directory"#,
        LOCAL_DIR.display()
    };

    let exclude_opts: Vec<_> = EXCLUDE_PATTERN
        .iter()
        .flat_map(|path| ["--exclude", path])
        .collect();

    let sync_opts: [String; 2] = {
        let remote = format!("{REMOTE}:");
        #[expect(clippy::expect_used)]
        let local_dir = LOCAL_DIR
            .to_str()
            .expect("[BUG] String to string failed?!")
            .to_owned();
        let remote_dir = format!("{remote}{SUBDIR}/");

        ceprintln!(
            Yellow,
            r#"Ensure remote subdir "{}" exists"#,
            remote_dir
        );
        Command::new("rclone")
            .args(["mkdir", &remote_dir])
            .status()
            .context("Failed to create remote directory")?;

        match direction {
            SyncDirection::Up => [local_dir, remote_dir],
            SyncDirection::Down => [remote_dir, local_dir],
        }
    };

    ceprintln!(
        Blue,
        r#"Syncing "{}" to "{}". Opts: "{:?}""#,
        sync_opts[0],
        sync_opts[1],
        extra_args
    );

    Command::new(",rclone")
        .arg("sync")
        .args(&exclude_opts)
        .args(extra_args)
        .args(&sync_opts)
        .spawn()
        .context("Failed to spawn ,rclone")?
        .wait()
        .map(|_| ())
        .map_err(Into::into)
}
