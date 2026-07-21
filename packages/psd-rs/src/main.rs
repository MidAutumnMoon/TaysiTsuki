//! psd: sync browser profiles to tmpfs via overlayfs.
//!
//! See `paths.rs` and `crash.rs` for the rationale behind the 5-path
//! state model.

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
use tracing::error;
use tracing::info;

mod browser;
mod config;
mod crash;
mod log;
mod overlay;
mod paths;
mod sync;

use browser::BrowserKind;
use browser::BrowserProfile;
use config::Config;
use strum::IntoEnumIterator;
use sync::State;

#[derive(Debug, Parser)]
#[command(
    name = "psd",
    version,
    about = "Sync browser profiles to tmpfs via overlayfs"
)]
struct Cli {
    /// Path to config.json. Required for sync commands; ignored by `preview`.
    /// Defaults to `$XDG_CONFIG_HOME/psd/config.json`.
    #[arg(long, global = true)]
    config: Option<PathBuf>,

    #[command(subcommand)]
    command: Command,
}

#[derive(Debug, Subcommand)]
enum Command {
    /// Mount overlays and symlink profiles (`ExecStart`).
    Startup,
    /// Rsync overlay view -> back-ovfs (`ExecStartPost` + timer).
    Resync,
    /// Final merge and unmount (`ExecStop`).
    Unsync,
    /// Detect and normalize ungraceful state.
    Recover,
    /// Generate shell completions to stdout.
    Completions {
        #[arg(value_enum)]
        shell: Shell,
    },
    /// Show what would be / is being managed. Scans all supported
    /// browsers; does not require config.
    Preview,
}

fn main() -> ExitCode {
    log::init();
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
    // Completions only need clap metadata -- bail early before State::new()
    // (which requires XDG_RUNTIME_DIR and would fail in build sandboxes).
    if let Command::Completions { shell } = &cli.command {
        let mut cmd = Cli::command();
        generate(*shell, &mut cmd, "psd", &mut stdout());
        return Ok(());
    }

    let state = State::new()?;

    match cli.command {
        // Sync commands: require config to know which browsers to manage.
        Command::Startup => {
            let cfg = load_config(cli.config.as_deref())?;
            let profiles = discover_configured(&cfg, &state)?;
            require_profiles(&profiles)?;
            cmd_startup(&state, &profiles)?;
        }
        Command::Resync => {
            let cfg = load_config(cli.config.as_deref())?;
            let profiles = discover_configured(&cfg, &state)?;
            require_profiles(&profiles)?;
            cmd_resync(&state, &profiles)?;
        }
        Command::Unsync => {
            let cfg = load_config(cli.config.as_deref())?;
            let profiles = discover_configured(&cfg, &state)?;
            require_profiles(&profiles)?;
            cmd_unsync(&state, &profiles)?;
        }
        Command::Recover => {
            let cfg = load_config(cli.config.as_deref())?;
            let profiles = discover_configured(&cfg, &state)?;
            require_profiles(&profiles)?;
            cmd_recover(&state, &profiles)?;
        }
        // Diagnostic: scan all supported browsers, no config needed.
        Command::Preview => {
            let profiles = discover_all(&state)?;
            cmd_preview(&state, &profiles);
        }
        // Handled above before State::new().
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

fn discover_configured(
    cfg: &Config,
    state: &State,
) -> Result<Vec<BrowserProfile>> {
    let home = home_dir_for(&state.user)?;
    let mut out = Vec::new();
    for &kind in &cfg.browsers {
        let found = BrowserProfile::discover(kind, &state.user, &home)
            .with_context(|| {
                format!("discovering {} profiles", kind.as_ref())
            })?;
        out.extend(found);
    }
    Ok(out)
}

fn discover_all(state: &State) -> Result<Vec<BrowserProfile>> {
    let home = home_dir_for(&state.user)?;
    let mut out = Vec::new();
    for kind in BrowserKind::iter() {
        match BrowserProfile::discover(kind, &state.user, &home) {
            Ok(found) => out.extend(found),
            Err(e) => {
                tracing::warn!(browser = kind.as_ref(), error = %e, "discovery failed");
            }
        }
    }
    Ok(out)
}

fn require_profiles(profiles: &[BrowserProfile]) -> Result<()> {
    if profiles.is_empty() {
        bail!("no browser profiles found for configured browsers");
    }
    Ok(())
}

fn home_dir_for(user_name: &str) -> Result<PathBuf> {
    use nix::unistd::User;
    let uid = nix::unistd::getuid().as_raw();
    let user = User::from_name(user_name)
        .with_context(|| format!("looking up user {user_name}"))?
        .or_else(|| User::from_uid(uid.into()).ok().flatten())
        .with_context(|| format!("user {user_name} not found"))?;
    Ok(user.dir.into_os_string().into())
}

fn cmd_startup(state: &State, profiles: &[BrowserProfile]) -> Result<()> {
    overlay::check_dependencies()?;

    // Write PID file first so resync/unsync see us as active during
    // startup. If startup fails partway, the PID file existing is
    // correct -- the session is partially live.
    state.mark_active()?;

    for p in profiles {
        // Recover first (idempotent if clean).
        crash::recover(&state.paths_for(p))?;
        sync::ensure_browser_not_running(p)?;
        sync::startup(state, p)?;
    }
    info!("startup complete");
    Ok(())
}

fn cmd_resync(state: &State, profiles: &[BrowserProfile]) -> Result<()> {
    if !state.is_active() {
        bail!("not active; refusing to resync");
    }
    for p in profiles {
        sync::resync(state, p)?;
    }
    Ok(())
}

fn cmd_unsync(state: &State, profiles: &[BrowserProfile]) -> Result<()> {
    for p in profiles {
        sync::unsync(state, p)?;
    }
    state.mark_inactive();
    info!("unsync complete");
    Ok(())
}

fn cmd_recover(state: &State, profiles: &[BrowserProfile]) -> Result<()> {
    for p in profiles {
        let paths = state.paths_for(p);
        let recovered = crash::recover(&paths)?;
        info!(
            dir = %paths.dir.display(),
            recovered,
            "recover done"
        );
    }
    Ok(())
}

fn cmd_preview(state: &State, profiles: &[BrowserProfile]) {
    println!("psd");
    println!("  active: {}", state.is_active());
    println!("  volatile root: {}", state.volatile_root.display());
    println!("  profiles:");
    for p in profiles {
        let paths = state.paths_for(p);
        println!("    - browser: {}", p.kind.as_ref());
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
    // du returns non-zero for minor issues like broken symlinks inside
    // the tree but still prints the size. Parse stdout regardless of
    // exit code; only fail if it's empty.
    let line = String::from_utf8_lossy(&out.stdout);
    Ok(line.split_whitespace().next().unwrap_or("?").to_owned())
}
