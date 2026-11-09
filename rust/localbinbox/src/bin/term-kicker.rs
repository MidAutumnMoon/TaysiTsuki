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

#[derive(Clone, Copy)]
enum Terminal {
    Foot,
    Monstar,
}

impl Terminal {
    /// Used when no terminal is focused.
    const DEFAULT: Self = Self::Monstar;

    fn from_app_id(app_id: &str) -> Option<Self> {
        match app_id {
            "foot" => Some(Self::Foot),
            "dev.rockorager.monstar" => Some(Self::Monstar),
            _ => None,
        }
    }

    const fn executable(self) -> &'static str {
        match self {
            Self::Foot => "foot",
            Self::Monstar => "monstar",
        }
    }
}

fn main() -> Result<()> {
    let (terminal, focused_cwd) = match focused_terminal()? {
        Some((terminal, focused_cwd)) => (terminal, focused_cwd),
        None => (Terminal::DEFAULT, None),
    };

    let cwd = match focused_cwd {
        Some(cwd) => cwd,
        None => var_os("HOME")
            .map(PathBuf::from)
            .context("$HOME is not set")?,
    };

    let executable = terminal.executable();
    let error = Command::new(executable).current_dir(&cwd).exec();
    Err(error).with_context(|| {
        format!("failed to exec {executable} in {}", cwd.display())
    })
}

fn focused_terminal() -> Result<Option<(Terminal, Option<PathBuf>)>> {
    let mut socket =
        Socket::connect().context("failed to connect to niri socket")?;

    let response = socket.send(Request::FocusedWindow)?;
    let focused_window = match response {
        Ok(Response::FocusedWindow(window)) => window,
        Ok(_) => bail!("unexpected response"),
        Err(error) => bail!("niri error: {error}"),
    };

    let Some(window) = focused_window else {
        return Ok(None);
    };
    let Some(terminal) =
        window.app_id.as_deref().and_then(Terminal::from_app_id)
    else {
        return Ok(None);
    };

    Ok(Some((terminal, window.pid.and_then(terminal_client_cwd))))
}

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
            let bytes = name.as_bytes();
            !bytes.is_empty()
                && bytes.iter().all(|byte| byte.is_ascii_digit())
        })
}
