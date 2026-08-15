//! Subprocess execution helpers.
//!
//! Every external command goes through here so failures carry the
//! program name, exit status, and captured stderr uniformly, instead
//! of each call site hand-rolling (and varying) its error handling.

use std::process::Command;
use std::process::Output;

use anyhow::Context;
use anyhow::Result;
use anyhow::bail;

/// Run to completion; on non-success, error with program, exit code,
/// and captured stderr. For commands whose only outcome is pass/fail.
pub fn run(cmd: &mut Command) -> Result<()> {
    let out = output(cmd)?;
    if !out.status.success() {
        bail!(
            "`{}` failed (exit {}): {}",
            cmd.get_program().to_string_lossy(),
            out.status.code().unwrap_or(-1),
            String::from_utf8_lossy(&out.stderr).trim(),
        );
    }
    Ok(())
}

/// Run to completion, returning raw stdout/stderr. For callers that
/// interpret specific exit codes or parse stdout (pgrep, mountpoint,
/// `flatpak override --show`, du).
pub fn output(cmd: &mut Command) -> Result<Output> {
    cmd.output().with_context(|| {
        format!("spawning `{}`", cmd.get_program().to_string_lossy())
    })
}
