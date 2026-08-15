//! psd: sync app profiles to tmpfs via overlayfs.
//!
//! The path model lives in `paths.rs`; crash recovery in `crash.rs`.

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
mod exec;
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
    // Completions need no runtime env; `State::new()` requires
    // XDG_RUNTIME_DIR, which is absent in build sandboxes.
    if let Command::Completions { shell } = &cli.command {
        let mut cmd = Cli::command();
        generate(*shell, &mut cmd, "psd", &mut stdout());
        return Ok(());
    }

    let state = State::new()?;

    // Sync commands need config; preview scans all supported apps.
    let profiles = match cli.command {
        Command::Preview => {
            let d = discover(&state, AppKind::iter())?;
            for (kind, e) in &d.failures {
                warn!(app = kind.as_ref(), error = %e, "discovery failed");
            }
            d.profiles
        }
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
    let discovered = discover(state, cfg.apps.iter().copied())?;
    // Report broken installs but carry on with what was found.
    for (kind, e) in &discovered.failures {
        error!(app = kind.as_ref(), error = %e, "discovery failed");
    }
    Ok(discovered.profiles)
}

/// Discovery results: profiles found plus per-app failures. One
/// broken app never aborts the scan; callers decide how failures are
/// reported.
#[derive(Debug)]
struct Discovered {
    profiles: Vec<AppProfile>,
    failures: Vec<(AppKind, anyhow::Error)>,
}

fn discover(
    state: &State,
    kinds: impl Iterator<Item = AppKind>,
) -> Result<Discovered> {
    let home = std::env::home_dir()
        .context("could not determine home directory")?;
    let mut out = Discovered {
        profiles: Vec::new(),
        failures: Vec::new(),
    };
    for kind in kinds {
        match AppProfile::discover(kind, &state.user, &home) {
            Ok(found) => out.profiles.extend(found),
            Err(e) => out.failures.push((kind, e)),
        }
    }
    Ok(out)
}

/// Run `op` on each profile independently; log and collect errors,
/// then fail once at the end. Partial progress stands -- the next run
/// converges from it. Returns each profile's outcome.
fn run_per_profile<O>(
    what: &'static str,
    state: &State,
    profiles: &[AppProfile],
    op: impl Fn(&State, &AppProfile) -> Result<O>,
) -> Result<Vec<O>> {
    let mut outcomes = Vec::with_capacity(profiles.len());
    let mut failed = Vec::new();
    for p in profiles {
        match op(state, p) {
            Ok(o) => outcomes.push(o),
            Err(e) => {
                error!(
                    op = what,
                    app = %p.kind.as_ref(),
                    dir = %p.path.display(),
                    error = %e,
                    "profile operation failed"
                );
                failed.push(p.path.display().to_string());
            }
        }
    }
    if failed.is_empty() {
        Ok(outcomes)
    } else {
        bail!("{what} failed for: {}", failed.join(", "))
    }
}

fn cmd_startup(state: &State, profiles: &[AppProfile]) -> Result<()> {
    if profiles.is_empty() {
        bail!("no app profiles found; nothing to manage");
    }
    overlay::check_dependencies()?;

    // Grant flatpak sandboxes tmpfs access before mounting
    // (idempotent).
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

    run_per_profile("startup", state, profiles, |state, p| {
        let paths = state.paths_for(p);
        // Already live (e.g. switch restart with the app open): a
        // success, and must skip the running check below.
        if sync::overlay_live(&paths)? {
            debug!(
                app = %p.kind.as_ref(),
                dir = %paths.dir.display(),
                "already live; skipping startup"
            );
            return Ok(());
        }
        crash::recover(&paths)?;
        // Mounting under a running app would corrupt its state.
        if sync::app_running(p.kind, &state.user)? {
            bail!(
                "{} is running (user={}); refusing to mount -- stop the \
                 app first",
                p.kind.process_name(),
                state.user
            );
        }
        sync::startup(state, p)
    })?;

    info!("startup complete");
    Ok(())
}

fn cmd_resync(state: &State, profiles: &[AppProfile]) -> Result<()> {
    run_per_profile("resync", state, profiles, sync::resync)?;
    Ok(())
}

fn cmd_unsync(state: &State, profiles: &[AppProfile]) -> Result<()> {
    let outcomes =
        run_per_profile("unsync", state, profiles, sync::unsync)?;
    let left_live = outcomes
        .iter()
        .filter(|o| matches!(o, sync::UnsyncOutcome::LeftLive))
        .count();
    if left_live > 0 {
        info!(
            left_live,
            "unsync complete; live overlays remain (apps running)"
        );
    } else {
        info!("unsync complete");
    }
    Ok(())
}

fn cmd_recover(state: &State, profiles: &[AppProfile]) -> Result<()> {
    run_per_profile("recover", state, profiles, |state, p| {
        let paths = state.paths_for(p);
        let outcome = crash::recover(&paths)?;
        info!(
            dir = %paths.dir.display(),
            recovered = matches!(outcome, crash::RecoverOutcome::Recovered),
            "recover done"
        );
        Ok(())
    })?;
    Ok(())
}

fn cmd_preview(state: &State, profiles: &[AppProfile]) {
    let live = profiles
        .iter()
        .filter(|p| state.paths_for(p).is_live())
        .count();
    println!("psd");
    println!("  profiles: {}/{} live", live, profiles.len());
    println!("  volatile root: {}", state.volatile_root.display());
    println!("  profiles:");
    for p in profiles {
        let paths = state.paths_for(p);
        println!("    - app:     {}", p.kind.as_ref());
        println!("      dir:     {}", paths.dir.display());
        println!("      backup:  {}", paths.backup.display());
        println!("      tmp:     {}", paths.tmp.display());
        // UPPER is the session's RAM cost; it only exists while live.
        if paths.is_live()
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
