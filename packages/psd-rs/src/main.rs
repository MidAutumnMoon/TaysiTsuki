//! psd: sync app profiles to tmpfs via overlayfs.
//!
//! See `paths.rs` for the 5-path state model and `crash.rs` for
//! ungraceful-state recovery.

use std::io::stdout;
use std::path::PathBuf;
use std::process::ExitCode;

use anyhow::Context;
use anyhow::Result;
use anyhow::bail;
use clap::CommandFactory;
use clap::Parser;
use clap::Subcommand;
use clap_complete::Shell;
use clap_complete::generate;
use tracing::debug;
use tracing::error;
use tracing::info;
use tracing::warn;

mod apps;
mod config;
mod crash;
mod flatpak;
mod overlay;
mod paths;
mod sync;

use apps::AppKind;
use apps::AppProfile;
use config::Config;
use strum::IntoEnumIterator;
use sync::State;

#[derive(Debug, Parser)]
#[command(
    name = "psd",
    version,
    about = "Sync app profiles to tmpfs via overlayfs"
)]
struct Cli {
    /// Path to config.json. Required for sync commands; ignored by `preview`.
    #[arg(long, global = true)]
    config: Option<PathBuf>,

    #[command(subcommand)]
    command: Command,
}

#[derive(Debug, Subcommand)]
enum Command {
    /// Mount overlays and symlink profiles.
    Startup,
    /// Rsync overlay view -> back-ovfs.
    Resync,
    /// Persist the delta; tear down unless the app is running (then
    /// the profile is persisted and left live).
    Unsync,
    /// Detect and normalize ungraceful state.
    Recover,
    /// Generate shell completions to stdout.
    Completions {
        #[arg(value_enum)]
        shell: Shell,
    },
    /// Show what would be / is being managed. Scans all supported apps;
    /// does not require config.
    Preview,
}

fn main() -> ExitCode {
    ino_tracing::init_tracing_subscriber();
    let cli = Cli::parse();
    match run(&cli) {
        Ok(()) => ExitCode::SUCCESS,
        Err(e) => {
            error!("{e:?}");
            ExitCode::FAILURE
        }
    }
}

fn run(cli: &Cli) -> Result<()> {
    // Completions only need clap metadata -- bail early before State::new(),
    // which requires XDG_RUNTIME_DIR (absent in build sandboxes).
    if let Command::Completions { shell } = &cli.command {
        let mut cmd = Cli::command();
        generate(*shell, &mut cmd, "psd", &mut stdout());
        return Ok(());
    }

    let state = State::new()?;

    // Sync commands need config; preview scans all apps tolerantly (a
    // broken install shouldn't hide the rest).
    let profiles = match cli.command {
        Command::Preview => discover(&state, AppKind::iter(), true)?,
        _ => load_profiles(cli, &state)?,
    };

    match cli.command {
        Command::Startup => cmd_startup(&state, &profiles)?,
        Command::Resync => cmd_resync(&state, &profiles)?,
        Command::Unsync => cmd_unsync(&state, &profiles)?,
        Command::Recover => cmd_recover(&state, &profiles)?,
        Command::Preview => cmd_preview(&state, &profiles),
        #[allow(clippy::unreachable)]
        Command::Completions { .. } => unreachable!(),
    }
    Ok(())
}

fn load_config(path: Option<&std::path::Path>) -> Result<Config> {
    let p = match path {
        Some(p) => p.to_owned(),
        None => Config::default_path()?,
    };
    Config::load(&p)
        .with_context(|| format!("loading config from {}", p.display()))
}

fn load_profiles(cli: &Cli, state: &State) -> Result<Vec<AppProfile>> {
    let cfg = load_config(cli.config.as_deref())?;
    let profiles = discover(state, cfg.apps.iter().copied(), false)?;
    if profiles.is_empty() {
        bail!("no app profiles found for configured apps");
    }
    Ok(profiles)
}

/// Discover profiles for the given apps. When `tolerant`, discovery
/// errors are logged as warnings instead of propagated (used by
/// `preview`, which shouldn't hide working apps behind one broken
/// install).
fn discover(
    state: &State,
    kinds: impl Iterator<Item = AppKind>,
    tolerant: bool,
) -> Result<Vec<AppProfile>> {
    let home = home_dir()?;
    let mut out = Vec::new();
    for kind in kinds {
        match AppProfile::discover(kind, &state.user, &home) {
            Ok(found) => out.extend(found),
            Err(e) if tolerant => {
                warn!(app = kind.as_ref(), error = %e, "discovery failed");
            }
            Err(e) => {
                return Err(e).with_context(|| {
                    format!("discovering {} profiles", kind.as_ref())
                });
            }
        }
    }
    Ok(out)
}

fn home_dir() -> Result<PathBuf> {
    std::env::var_os("HOME")
        .map(PathBuf::from)
        .context("HOME is not set")
}

/// Run `op` on each profile independently: per-profile errors are
/// logged and deferred (partial progress is a state the next run
/// converges from), then reported as one error at the end.
fn run_per_profile(
    state: &State,
    profiles: &[AppProfile],
    op: impl Fn(&State, &AppProfile) -> Result<()>,
) -> Result<()> {
    let mut failed = Vec::new();
    for p in profiles {
        if let Err(e) = op(state, p) {
            error!(
                app = %p.kind.as_ref(),
                dir = %p.path.display(),
                error = %e,
                "profile operation failed"
            );
            failed.push(p.path.display().to_string());
        }
    }
    if failed.is_empty() {
        Ok(())
    } else {
        bail!("failed for: {}", failed.join(", "))
    }
}

fn cmd_startup(state: &State, profiles: &[AppProfile]) -> Result<()> {
    overlay::check_dependencies()?;

    // Grant flatpak sandboxes access to the psd tmpfs before mounting.
    // Idempotent; one call per unique flatpak app-id.
    for kind in profiles.iter().map(|p| p.kind) {
        if let Some(app_id) = kind.flatpak_id()
            && let Err(e) =
                flatpak::ensure_psd_access(app_id, &state.volatile_root)
        {
            return Err(e).with_context(|| {
                format!("granting flatpak access for {app_id}")
            });
        }
    }

    // Write PID file first so resync/unsync see us as active during
    // startup. If startup fails partway, the PID file existing is
    // correct -- the session is partially live.
    state.mark_active()?;

    run_per_profile(state, profiles, |state, p| {
        let paths = state.paths_for(p);
        // Converge: an already-live profile (e.g. systemd restart on a
        // NixOS switch, with the app open) is a success -- and must
        // skip the app-running check below.
        if paths.is_live() {
            debug!(
                app = %p.kind.as_ref(),
                dir = %paths.dir.display(),
                "already live; skipping startup"
            );
            return Ok(());
        }
        // Recover first (no-op when clean or live).
        crash::recover(&paths)?;
        sync::ensure_app_not_running(p.kind, &state.user)?;
        sync::startup(state, p)
    })?;

    info!("startup complete");
    Ok(())
}

fn cmd_resync(state: &State, profiles: &[AppProfile]) -> Result<()> {
    // Non-live profiles are skipped inside sync::resync; liveness (not
    // the PID file) decides what gets synced.
    run_per_profile(state, profiles, sync::resync)
}

fn cmd_unsync(state: &State, profiles: &[AppProfile]) -> Result<()> {
    run_per_profile(state, profiles, sync::unsync)?;

    // The PID file means "a session is live" (it gates resync): keep
    // it while any overlay remains -- whether left live deliberately
    // (app running) or by a partial failure.
    if profiles.iter().any(|p| state.paths_for(p).is_live()) {
        info!("unsync complete; some profiles left live (apps running?)");
    } else {
        state.mark_inactive();
        info!("unsync complete");
    }
    Ok(())
}

fn cmd_recover(state: &State, profiles: &[AppProfile]) -> Result<()> {
    run_per_profile(state, profiles, |state, p| {
        let paths = state.paths_for(p);
        let recovered = crash::recover(&paths)?;
        info!(
            dir = %paths.dir.display(),
            recovered,
            "recover done"
        );
        Ok(())
    })
}

fn cmd_preview(state: &State, profiles: &[AppProfile]) {
    println!("psd");
    println!("  active: {}", state.is_active());
    println!("  volatile root: {}", state.volatile_root.display());
    println!("  profiles:");
    for p in profiles {
        let paths = state.paths_for(p);
        println!("    - app:     {}", p.kind.as_ref());
        println!("      dir:     {}", paths.dir.display());
        println!("      backup:  {}", paths.backup.display());
        println!("      tmp:     {}", paths.tmp.display());
        // UPPER is the overlay delta in tmpfs -- only exists when active.
        // This is the actual RAM cost of the session.
        if state.is_active()
            && let Ok(delta) = dir_size_human(&paths.upper)
        {
            println!("      delta:   {delta}");
        }
    }
}

fn dir_size_human(p: &std::path::Path) -> Result<String> {
    let out = std::process::Command::new("du")
        .args(["-sh", "--"])
        .arg(p)
        .output()
        .context("spawning du")?;
    // du returns non-zero for broken symlinks inside the tree but still
    // prints the size -- parse stdout regardless of exit code.
    let line = String::from_utf8_lossy(&out.stdout);
    Ok(line.split_whitespace().next().unwrap_or("?").to_owned())
}
