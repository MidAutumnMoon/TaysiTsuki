//! Custom rclone wrapper.

use std::process::Command;

use anyhow::Context;
use anyhow::Result;
use maintenance::RCLONE_CONF;

const RCLONE_PATH: Option<&str> = option_env!("CFG_RCLONE_PATH");

fn main() -> Result<()> {
    let remaining_opts = std::env::args().skip(1);

    Command::new(RCLONE_PATH.unwrap_or("rclone"))
        // Bug with cgo resolver?
        .env("GODEBUG", "netdns=go")
        .arg("--config")
        .arg(&*RCLONE_CONF)
        .arg("--progress")
        .arg("--human-readable")
        .args(["--multi-thread-cutoff", "128M"])
        .args(["--multi-thread-streams", "4"])
        .args(remaining_opts)
        .spawn()
        .context("Failed to spawn rclone")?
        .wait()
        .map(|_| ())
        .map_err(Into::into)
}
