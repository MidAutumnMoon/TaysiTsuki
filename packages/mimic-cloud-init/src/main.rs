use anyhow::Context as _;
use anyhow::Result as AnyResult;
use anyhow::bail;

use crate::fs::MountAndRead;

mod blkid;
mod fs;
mod net;

fn main_result() -> AnyResult<()> {
    eprintln!("mimic-cloud-init start");
    let Some(config_drive) = blkid::find_config_drive()? else {
        bail!("Unable to find config drive")
    };
    let network_config = MountAndRead::new(&config_drive)
        .context("Failed to mount config drive")?
        .read_file("network-config")
        .context("Failed to read network config from config drive")?;
    net::render_network_config(&network_config)
        .context("Failed to render network config")?;
    Ok(())
}

fn main() {
    main_result()
        .map_err(|err| {
            eprintln!("{err:?}");
            std::process::exit(1);
        })
        .unwrap();
}
