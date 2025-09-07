use std::collections::HashSet;
use std::path::PathBuf;
use std::process::Command;

use anyhow::Context;
use anyhow::Result as AnyResult;
use anyhow::bail;
use tap::Pipe;

pub fn find_config_drive() -> AnyResult<Option<PathBuf>> {
    eprintln!("find_config_drive");

    // TODO: handle upper case "cidata"?
    let cidata_devs = devices_match_label("cidata")?;
    dbg!(&cidata_devs);

    // TODO: handle "vfat" type?
    let iso9660_devs = devices_match_fstype("iso9660")?;
    dbg!(&iso9660_devs);

    let devs = cidata_devs
        .intersection(&iso9660_devs)
        .map(PathBuf::from)
        .collect::<Vec<_>>();
    dbg!(&devs);

    let dev = match &devs[..] {
        [] => return Ok(None),
        [dev] => dev.clone(),
        // TODO: handle multiple drives
        _ => bail!(
            "Found multiple config drive, but this tool currently only supports one"
        ),
    };
    dbg!(&dev);

    Ok(Some(dev))
}

#[allow(clippy::option_if_let_else)]
pub fn devices_match_label(label: &str) -> AnyResult<HashSet<String>> {
    let param = format!("--match-token=LABEL={label}");
    if let Some(output) = blkid(&[&param, "--output=device"])? {
        output
            .lines()
            .map(ToOwned::to_owned)
            .collect::<HashSet<_>>()
            .pipe(Ok)
    } else {
        Ok(HashSet::default())
    }
}

#[allow(clippy::option_if_let_else)]
pub fn devices_match_fstype(fstype: &str) -> AnyResult<HashSet<String>> {
    let param = format!("--match-token=TYPE={fstype}");
    if let Some(output) = blkid(&[&param, "--output=device"])? {
        output
            .lines()
            .map(ToOwned::to_owned)
            .collect::<HashSet<_>>()
            .pipe(Ok)
    } else {
        Ok(HashSet::default())
    }
}

/// Run `blkid` and capture the output. By the way this is also
/// how cloud-init implements it.
pub fn blkid(params: &[&str]) -> AnyResult<Option<String>> {
    dbg!(&params);
    let output = Command::new("blkid")
        .args(params)
        .output()
        .context("Failed to run command blkid")?;
    if !output.status.success() {
        let stderr = output.stderr.pipe_as_ref(String::from_utf8_lossy);
        if stderr.is_empty() {
            return Ok(None);
        }
        bail!("blkid error. Stderr: {stderr}");
    }
    output
        .stdout
        .pipe(String::from_utf8)
        .context("Failed to convert blkid output to String")?
        .pipe(Some)
        .pipe(Ok)
}
