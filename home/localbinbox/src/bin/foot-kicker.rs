use anyhow::Context as _;
use anyhow::Result;
use anyhow::bail;
use niri_ipc::Request;
use niri_ipc::Response;
use niri_ipc::socket::Socket;

use std::env::var_os;
use std::fs::read_link;
use std::fs::read_to_string;
use std::os::unix::ffi::OsStrExt as _;
use std::os::unix::process::CommandExt as _;
use std::path::Path;
use std::path::PathBuf;
use std::process::Command;

// A wrapper script to launch foot with the same cwd.
fn main() -> Result<()> {
    let cwd = match focused_foot_cwd()? {
        Some(cwd) => cwd,
        None => var_os("HOME")
            .map(PathBuf::from)
            .context("$HOME is not set")?,
    };

    let err = Command::new("foot").current_dir(&cwd).exec();
    Err(err).with_context(|| {
        format!("failed to exec foot in {}", cwd.display())
    })
}

fn focused_foot_cwd() -> Result<Option<PathBuf>> {
    let mut socket =
        Socket::connect().context("failed to connect to niri socket")?;

    let focused_win = match socket.send(Request::FocusedWindow)? {
        Ok(Response::FocusedWindow(w)) => w,
        Ok(_) => bail!("unexpected response"),
        Err(err) => bail!("niri error: {err}"),
    };

    // Deliberately accept standalone Foot only. A footclient window exposes
    // the shared server PID, which cannot identify one terminal client.
    Ok(focused_win
        .filter(|w| w.app_id.as_deref() == Some("foot"))
        .and_then(|w| w.pid)
        .and_then(terminal_client_cwd))
}

/// Get the cwd of Foot's unique PTY client process.
fn terminal_client_cwd(pid: i32) -> Option<PathBuf> {
    let children =
        read_to_string(format!("/proc/{pid}/task/{pid}/children")).ok()?;

    let mut clients = children
        .split_whitespace()
        .filter_map(|child| child.parse::<i32>().ok())
        .filter(|&child| child_has_pty_stdin(child));

    let client = clients.next()?;
    if clients.next().is_some() {
        return None;
    }

    read_link(format!("/proc/{client}/cwd")).ok()
}

fn child_has_pty_stdin(pid: i32) -> bool {
    let Ok(stdin) = read_link(format!("/proc/{pid}/fd/0")) else {
        return false;
    };

    stdin.parent() == Some(Path::new("/dev/pts"))
        && stdin.file_name().is_some_and(|name| {
            let name = name.as_bytes();
            !name.is_empty()
                && name.iter().all(|byte| byte.is_ascii_digit())
        })
}
