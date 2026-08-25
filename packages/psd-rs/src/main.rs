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
mod checkpoint;
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
        Err(error) => {
            // Alternate Display includes anyhow's context chain without the
            // debug backtrace, which is noise for normal operational errors.
            error!("{error:#}");
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
    let _lock = if matches!(&cli.command, Command::Preview) {
        None
    } else {
        Some(state.acquire_lock()?)
    };
    // Sync commands need config; preview scans all supported apps.
    let profiles = match cli.command {
        Command::Preview => {
            let d = discover(&state, AppKind::iter())?;
            for (kind, e) in &d.failures {
                warn!(app = kind.as_ref(), error = %format_args!("{e:#}"), "discovery failed");
            }
            d.profiles
        }
        _ => load_profiles(cli, &state)?,
    };
    validate_profiles(&state, &profiles)?;

    match cli.command {
        Command::Startup => cmd_startup(&state, &profiles)?,
        Command::Resync => cmd_resync(&state, &profiles)?,
        Command::Unsync => cmd_unsync(&state, &profiles)?,
        Command::Recover => cmd_recover(&state, &profiles)?,
        Command::Preview => cmd_preview(&state, &profiles)?,
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
        error!(app = kind.as_ref(), error = %format_args!("{e:#}"), "discovery failed");
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

fn validate_profiles(
    state: &State,
    profiles: &[AppProfile],
) -> Result<()> {
    let mut remaining = profiles;
    while let Some((profile, rest)) = remaining.split_first() {
        if !profile.path.is_absolute() {
            bail!(
                "profile path must be absolute: {}",
                profile.path.display()
            );
        }
        let paths = state.paths_for(profile);
        for path in [&paths.backup, &paths.upper, &paths.work] {
            validate_overlay_option_path(path)?;
        }
        for other in rest {
            if profile.path == other.path {
                bail!(
                    "profile {} was discovered more than once",
                    profile.path.display()
                );
            }
            if profile.path.starts_with(&other.path)
                || other.path.starts_with(&profile.path)
            {
                bail!(
                    "nested profiles are unsafe to manage together: {} and {}",
                    profile.path.display(),
                    other.path.display()
                );
            }
            let other_paths = state.paths_for(other);
            if paths.tmp == other_paths.tmp {
                bail!(
                    "profiles {} and {} map to the same volatile path {}; \
                     rename one profile",
                    profile.path.display(),
                    other.path.display(),
                    paths.tmp.display()
                );
            }
        }
        remaining = rest;
    }
    Ok(())
}

fn validate_overlay_option_path(path: &std::path::Path) -> Result<()> {
    let value = path.to_str().with_context(|| {
        format!(
            "overlay path is not valid UTF-8 and cannot be encoded safely: {}",
            path.display()
        )
    })?;
    if value
        .bytes()
        .any(|byte| matches!(byte, b',' | b':' | b'\\'))
    {
        bail!(
            "overlay path contains `,`, `:`, or `\\`, which fuse-overlayfs \
             treats as option syntax: {}",
            path.display()
        );
    }
    Ok(())
}

/// Run `op` on every profile, log each failure, then return one aggregate
/// error. Successful mount operations remain independently supervised and
/// healthy while the failed profile is repaired on a later run.
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
                    error = %format_args!("{e:#}"),
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
        match crash::recover(&paths)? {
            crash::RecoverOutcome::Live
            | crash::RecoverOutcome::Reattached
            | crash::RecoverOutcome::Reconnected => {
                debug!(
                    app = %p.kind.as_ref(),
                    dir = %paths.dir.display(),
                    "profile overlay is live; skipping startup"
                );
                return Ok(());
            }
            crash::RecoverOutcome::Absent => {
                warn!(
                    app = %p.kind.as_ref(),
                    dir = %paths.dir.display(),
                    "no durable profile found; skipping startup"
                );
                return Ok(());
            }
            crash::RecoverOutcome::Already
            | crash::RecoverOutcome::Recovered => {}
        }
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
    let outcomes =
        run_per_profile("resync", state, profiles, |state, profile| {
            reconnect_if_disconnected(state, profile)?;
            sync::resync(state, profile)
        })?;
    let source_changed = outcomes
        .iter()
        .filter(|outcome| {
            matches!(outcome, sync::ResyncOutcome::SourceChanged)
        })
        .count();
    if source_changed > 0 {
        bail!(
            "{source_changed} profile checkpoint(s) were not advanced because \
             their source changed; previous committed checkpoints remain safe"
        );
    }
    Ok(())
}

fn cmd_unsync(state: &State, profiles: &[AppProfile]) -> Result<()> {
    run_per_profile("unsync", state, profiles, |state, profile| {
        reconnect_if_disconnected(state, profile)?;
        sync::unsync(state, profile)
    })?;
    info!("unsync complete");
    Ok(())
}

fn reconnect_if_disconnected(
    state: &State,
    profile: &AppProfile,
) -> Result<()> {
    let paths = state.paths_for(profile);
    if paths.session_state()? == paths::SessionState::DisconnectedMount {
        let outcome = crash::recover(&paths)?;
        if outcome != crash::RecoverOutcome::Reconnected {
            bail!(
                "expected disconnected profile {} to reconnect, got \
                 {outcome:?}",
                profile.path.display()
            );
        }
    }
    Ok(())
}

fn cmd_recover(state: &State, profiles: &[AppProfile]) -> Result<()> {
    run_per_profile("recover", state, profiles, |state, p| {
        let paths = state.paths_for(p);
        let outcome = crash::recover(&paths)?;
        info!(
            dir = %paths.dir.display(),
            ?outcome,
            "recover done"
        );
        Ok(())
    })?;
    Ok(())
}

fn cmd_preview(state: &State, profiles: &[AppProfile]) -> Result<()> {
    let mut live = 0;
    let mut states = Vec::with_capacity(profiles.len());
    for profile in profiles {
        let paths = state.paths_for(profile);
        let session = paths.session_state().with_context(|| {
            format!(
                "inspect {} profile at {}",
                profile.kind.as_ref(),
                profile.path.display()
            )
        })?;
        let committed_at =
            checkpoint::committed_at(&paths).with_context(|| {
                format!(
                    "inspect checkpoint for {}",
                    profile.path.display()
                )
            })?;
        if session == paths::SessionState::Live {
            live += 1;
        }
        states.push((profile, paths, session, committed_at));
    }

    println!("psd");
    println!("  profiles: {live}/{} live", profiles.len());
    println!("  volatile root: {}", state.volatile_root.display());
    println!("  profiles:");
    for (profile, paths, session, committed_at) in states {
        println!("    - app:        {}", profile.kind.as_ref());
        println!("      state:      {session}");
        println!(
            "      checkpoint: {}",
            format_checkpoint_age(committed_at)
        );
        println!("      dir:        {}", paths.dir.display());
        println!("      backup:     {}", paths.backup.display());
        println!("      tmp:        {}", paths.tmp.display());
        // UPPER is the session's RAM cost; it only exists while live.
        if session == paths::SessionState::Live
            && let Ok(delta) = dir_size_human(&paths.upper)
        {
            println!("      delta:      {delta}");
        }
    }
    Ok(())
}

fn format_checkpoint_age(
    modified: Option<std::time::SystemTime>,
) -> String {
    let Some(modified) = modified else {
        return "none".to_owned();
    };
    let Ok(age) = std::time::SystemTime::now().duration_since(modified)
    else {
        return "in the future (clock changed)".to_owned();
    };
    let seconds = age.as_secs();
    match seconds {
        0..=59 => format!("{seconds}s ago"),
        60..=3599 => format!("{}m ago", seconds / 60),
        3600..=86_399 => format!("{}h ago", seconds / 3600),
        _ => format!("{}d ago", seconds / 86_400),
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

#[cfg(test)]
#[expect(clippy::unwrap_used, reason = "Tests")]
mod tests {
    use std::ffi::OsString;
    use std::os::unix::ffi::OsStringExt as _;

    use super::*;

    #[test]
    fn overlay_option_paths_reject_fuse_delimiters() {
        validate_overlay_option_path(std::path::Path::new(
            "/home/user/profile",
        ))
        .unwrap();
        for path in [
            "/home/user/pro,file",
            "/home/user/pro:file",
            "/home/user/pro\\file",
        ] {
            assert!(
                validate_overlay_option_path(std::path::Path::new(path))
                    .is_err()
            );
        }
    }

    #[test]
    fn overlay_option_paths_reject_non_utf8() {
        let path = std::path::PathBuf::from(OsString::from_vec(vec![
            b'/', b't', b'm', b'p', b'/', 0xff,
        ]));
        assert!(validate_overlay_option_path(&path).is_err());
    }

    fn profile(path: std::path::PathBuf, suffix: &str) -> AppProfile {
        AppProfile {
            kind: AppKind::Firefox,
            user: "user".to_owned(),
            path,
            suffix: suffix.to_owned(),
        }
    }

    #[test]
    fn profile_validation_rejects_conflicting_layouts() {
        let temp = tempfile::tempdir().unwrap();
        let root = temp.path();
        let state = State {
            volatile_root: root.join("runtime"),
            user: "user".to_owned(),
        };
        let duplicate = root.join("duplicate");
        let nested_parent = root.join("nested");

        for (profiles, expected) in [
            (
                vec![
                    profile(duplicate.clone(), "duplicate"),
                    profile(duplicate.clone(), "duplicate"),
                ],
                "discovered more than once",
            ),
            (
                vec![
                    profile(nested_parent.clone(), "nested"),
                    profile(nested_parent.join("child"), "child"),
                ],
                "nested profiles",
            ),
            (
                vec![
                    profile(root.join("one/shared"), "shared"),
                    profile(root.join("two/shared"), "shared"),
                ],
                "same volatile path",
            ),
        ] {
            let error = validate_profiles(&state, &profiles).unwrap_err();
            assert!(
                error.to_string().contains(expected),
                "expected {expected:?}, got {error:#}"
            );
        }
    }
}
