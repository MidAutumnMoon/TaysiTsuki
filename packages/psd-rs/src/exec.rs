//! Subprocess execution helpers.
//!
//! Failures carry the program name, exit status, and captured stderr
//! uniformly -- call sites never hand-roll their own.

use std::process::Command;
use std::process::Output;

use anyhow::Context as _;
use anyhow::Result;
use anyhow::bail;

/// Run to completion; fail with exit code and stderr on non-success.
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

/// Run to completion, returning the raw `Output` -- for callers that
/// interpret exit codes or parse stdout.
pub fn output(cmd: &mut Command) -> Result<Output> {
    cmd.output().with_context(|| {
        format!("spawning `{}`", cmd.get_program().to_string_lossy())
    })
}
