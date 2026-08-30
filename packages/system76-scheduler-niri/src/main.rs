use std::sync::mpsc;
use std::thread;
use std::time::Duration;

use dbus::blocking::Connection as DbusConn;
use niri_ipc::Event as NiriEvent;
use niri_ipc::Request as NiriRequest;
use niri_ipc::Response as NiriResponse;
use niri_ipc::socket::Socket as NiriSocket;
use niri_ipc::state::EventStreamStatePart as _;
use niri_ipc::state::WindowsState;
use rootcause::prelude::Report;
use rootcause::prelude::ResultExt as _;
use tracing::error;
use tracing::info;
use tracing::instrument;

const SCHEDULER_DEST: &str = "com.system76.Scheduler";
const SCHEDULER_PATH: &str = "/com/system76/Scheduler";
const SCHEDULER_IFACE: &str = "com.system76.Scheduler";

const DBUS_TIMEOUT: Duration = Duration::from_secs(1);
const COALESCE_INTERVAL: Duration = Duration::from_millis(70);

#[derive(Debug)]
struct ForegroundWindow {
    pid: u32,
    window_id: u64,
    title: Option<String>,
}

fn main() -> Result<(), Report> {
    let _log_guard = ino_tracing::init_tracing_subscriber();

    //
    // Probe Niri & setup event stream
    //

    let mut niri_socket = NiriSocket::connect()
        .context("Failed to connect to niri socket")?;

    match niri_socket
        .send(NiriRequest::EventStream)
        .context("Failed to send event stream request to niri")?
    {
        Ok(NiriResponse::Handled) => {
            info!("Niri successfully handled event stream request");
        }
        Ok(resp) => {
            rootcause::bail!(
                "Niri didn't handle event stream request: {resp:?}"
            );
        }
        Err(message) => {
            rootcause::bail!(
                "Niri rejected event stream request: {message}"
            );
        }
    }

    //
    // Setup dbus worker & channel
    //

    let dbus_conn = DbusConn::new_system()
        .context("Failed to connect to the system bus")?;

    let (foreground_tx, foreground_rx) =
        mpsc::channel::<ForegroundWindow>();

    let _scheduler_worker = thread::Builder::new()
        .name("scheduler".into())
        .spawn(move || scheduler_worker(&dbus_conn, &foreground_rx))
        .context("Failed to start scheduler worker")?;

    let mut windows = WindowsState::default();
    let mut read_event = niri_socket.read_events();

    loop {
        let event = read_event().context("Niri event stream closed")?;

        // Decide whether this event can require updating the scheduler
        // before moving it into WindowsState::apply().
        //
        // WindowsChanged covers the initial event-stream snapshot, so this
        // also initializes the scheduler with the window that was already
        // focused when this program started.
        //
        // WindowOpenedOrChanged can itself introduce a focused window, so
        // don't rely exclusively on WindowFocusChanged.
        let foreground_may_have_changed = match &event {
            NiriEvent::WindowsChanged { .. }
            | NiriEvent::WindowFocusChanged { .. } => true,

            NiriEvent::WindowOpenedOrChanged { window } => {
                window.is_focused
            }

            _ => false,
        };

        // `.apply` consumes the event, so is windows.apply() returns Some,
        // we know the fact the event is not a window event.
        //
        // Also that's why we need to match &event before apply().
        if windows.apply(event).is_some() {
            continue;
        }

        if !foreground_may_have_changed {
            continue;
        }

        let Some(window) =
            windows.windows.values().find(|window| window.is_focused)
        else {
            // Niri can have no focused toplevel, for example when a
            // layer-shell surface has focus. Keep the previous scheduler
            // foreground process in that case.
            continue;
        };

        let Some(pid) = window.pid.and_then(|pid| u32::try_from(pid).ok())
        else {
            continue;
        };

        foreground_tx
            .send(ForegroundWindow {
                pid,
                window_id: window.id,
                title: window.title.clone(),
            })
            .context("Scheduler worker stopped")?;
    }
}

#[instrument(skip_all)]
fn scheduler_worker(
    dbus_conn: &DbusConn,
    foreground_rx: &mpsc::Receiver<ForegroundWindow>,
) {
    let scheduler =
        dbus_conn.with_proxy(SCHEDULER_DEST, SCHEDULER_PATH, DBUS_TIMEOUT);

    let mut last_pid = None;

    while let Ok(mut fg_win) = foreground_rx.recv() {
        // Sleep for a few ms to let events coalesce.
        thread::sleep(COALESCE_INTERVAL);

        // Drain every event arrived in the coalesce window,
        // keep the lastest one.
        while let Ok(newer_window) = foreground_rx.try_recv() {
            fg_win = newer_window;
        }

        // Avoids dbus call if window not changed or somehow scrolled back.
        if last_pid == Some(fg_win.pid) {
            continue;
        }

        let dbus_result = scheduler.method_call::<(), _, _, _>(
            SCHEDULER_IFACE,
            "SetForegroundProcess",
            (fg_win.pid,),
        );

        match dbus_result {
            Ok(()) => {
                // Only suppress future duplicates after a successful call.
                // If D-Bus failed, the next focus event can retry.
                last_pid = Some(fg_win.pid);

                info!(
                    pid = fg_win.pid,
                    window_id = fg_win.window_id,
                    title = ?fg_win.title,
                    "Set foreground process"
                );
            }

            Err(why) => {
                error!(
                    error = ?why,
                    pid = fg_win.pid,
                    window_id = fg_win.window_id,
                    title = ?fg_win.title,
                    "Failed to set foreground process"
                );
            }
        }
    }
}
