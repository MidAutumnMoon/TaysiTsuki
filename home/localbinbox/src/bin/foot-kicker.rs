use anyhow::Context as _;
use anyhow::Result;
use anyhow::bail;
use niri_ipc::Action;
use niri_ipc::Request;
use niri_ipc::Response;
use niri_ipc::socket::Socket;
use tap::Pipe as _;

use std::fs::read_link;
use std::fs::read_to_string;

enum FootVariant {
    Foot,
    FootClient,
}

impl FootVariant {
    fn from_arg(arg: &str) -> Result<Self> {
        match arg {
            "foot" => Ok(Self::Foot),
            "footclient" => Ok(Self::FootClient),
            unknown => bail!(
                "unknown foot variant: {unknown:?} (expected \"foot\" or \"footclient\")"
            ),
        }
    }

    fn binary(self) -> &'static str {
        match self {
            Self::Foot => "foot",
            Self::FootClient => "footclient",
        }
    }
}

// A wrapper script to launch foot with the same cwd.
fn main() -> Result<()> {
    let variant = match std::env::args().nth(1) {
        Some(arg) => FootVariant::from_arg(&arg)?,
        None => FootVariant::Foot,
    };
    let mut socket =
        Socket::connect().context("failed to connect to niri socket")?;

    // Get the focused window.
    let focused_win = match socket.send(Request::FocusedWindow)? {
        Ok(Response::FocusedWindow(w)) => w,
        Ok(_) => bail!("unexpected response"),
        Err(err) => bail!("niri error: {err}"),
    };

    let cwd = focused_win
        .filter(|w| w.app_id.as_deref() == Some("foot"))
        .and_then(|w| w.pid)
        .and_then(shell_cwd);

    let action_cmd = {
        let mut command = vec![variant.binary().to_owned()];
        if let Some(cwd) = cwd {
            command.extend_from_slice(&["-D".into(), cwd]);
        }
        Action::Spawn { command }
    };

    socket
        .send(Request::Action(action_cmd))?
        .map_err(|err| anyhow::anyhow!("niri error: {err}"))?;

    Ok(())
}

/// Get the cwd of the shell running inside foot.
fn shell_cwd(pid: i32) -> Option<String> {
    // List the children of the main thread, and the first child
    // would typically be the shell. Edge cases are too edgey to consider.
    let children = format!("/proc/{pid}/task/{pid}/children")
        .pipe(read_to_string)
        .ok()?;

    let might_be_shell = children.split_whitespace().next()?;

    format!("/proc/{might_be_shell}/cwd")
        .pipe(read_link)
        .ok()?
        .into_os_string()
        .into_string()
        .ok()
}
