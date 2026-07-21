//! Firefox profile discovery via `profiles.ini`.
//!
//! Supports both legacy (`~/.mozilla/firefox/profiles.ini`) and XDG
//! (`~/.config/mozilla/firefox/profiles.ini`) locations.

use std::path::Path;
use std::path::PathBuf;

use anyhow::Context;
use anyhow::Result;
use tracing::debug;
use tracing::warn;

use crate::browser::with_suffix;
use crate::browser::BrowserKind;
use crate::browser::BrowserProfile;

pub fn discover(user: &str, home: &Path) -> Result<Vec<BrowserProfile>> {
    let mut out = Vec::new();
    // XDG first (Firefox 147+), then legacy.
    for base in [
        home.join(".config/mozilla/firefox"),
        home.join(".mozilla/firefox"),
    ] {
        let ini = base.join("profiles.ini");
        if !ini.is_file() {
            continue;
        }
        debug!(path = %ini.display(), "parsing firefox profiles.ini");
        match parse_profiles_ini(&ini, &base) {
            Ok(paths) => {
                for p in paths {
                    // Dedup: same path may appear in both locations.
                    if !out.iter().any(|b: &BrowserProfile| b.path == p) {
                        out.push(with_suffix(
                            BrowserKind::Firefox,
                            user,
                            p,
                        )?);
                    }
                }
            }
            Err(e) => {
                warn!(error = %e, path = %ini.display(), "failed to parse profiles.ini");
            }
        }
    }
    Ok(out)
}

/// Minimal INI parser sufficient for profiles.ini.
/// Returns resolved (absolute) profile paths.
fn parse_profiles_ini(ini: &Path, base: &Path) -> Result<Vec<PathBuf>> {
    let content = std::fs::read_to_string(ini)
        .with_context(|| format!("reading {}", ini.display()))?;
    let mut paths = Vec::new();
    let mut current_is_relative: Option<bool> = None;
    let mut current_path: Option<String> = None;
    for line in content.lines() {
        let line = line.trim();
        if line.is_empty()
            || line.starts_with(';')
            || line.starts_with('#')
        {
            continue;
        }
        if line.starts_with('[') && line.ends_with(']') {
            // New section: flush previous.
            if let (Some(p), Some(rel)) =
                (current_path.take(), current_is_relative.take())
            {
                paths.push(resolve_profile_path(&p, rel, base));
            }
            continue;
        }
        if let Some((k, v)) = line.split_once('=') {
            let (k, v) = (k.trim(), v.trim());
            match k.to_ascii_lowercase().as_str() {
                "path" => current_path = Some(v.to_owned()),
                "isrelative" => {
                    current_is_relative =
                        Some(v == "1" || v.eq_ignore_ascii_case("true"));
                }
                _ => {}
            }
        }
    }
    if let (Some(p), Some(rel)) = (current_path, current_is_relative) {
        paths.push(resolve_profile_path(&p, rel, base));
    }
    Ok(paths)
}

fn resolve_profile_path(
    p: &str,
    is_relative: bool,
    base: &Path,
) -> PathBuf {
    if is_relative {
        base.join(p)
    } else {
        PathBuf::from(p)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parses_relative_and_absolute() {
        let tmp = tempfile::tempdir().unwrap();
        let base = tmp.path();
        let ini = base.join("profiles.ini");
        std::fs::write(
            &ini,
            "[Profile0]\nName=default\nIsRelative=1\nPath=abc.def\n\n\
             [Profile1]\nName=other\nIsRelative=0\nPath=/opt/other\n",
        )
        .unwrap();
        let paths = parse_profiles_ini(&ini, base).unwrap();
        assert_eq!(paths.len(), 2);
        assert_eq!(paths[0], base.join("abc.def"));
        assert_eq!(paths[1], PathBuf::from("/opt/other"));
    }
}
