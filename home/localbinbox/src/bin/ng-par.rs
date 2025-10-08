use std::env::current_dir;
use std::path::Path;

use anyhow::Context;
use anyhow::Result;
use anyhow::ensure;
use ino_color::InoColor;
use ino_color::fg::Yellow;
use itertools::Itertools;
use localbinbox::collect_read_dir;

fn main() -> Result<()> {
    let paths = {
        let args = std::env::args().skip(1).collect_vec();
        let cwd = current_dir()?;
        let inputs = if args.is_empty() {
            eprintln!("{}", "No files, read current dir".fg::<Yellow>());
            collect_read_dir(&cwd)?
        } else {
            args.into_iter()
                .map(|p| {
                    let p = Path::new(&p);
                    if p.is_absolute() {
                        p.to_owned()
                    } else {
                        cwd.join(p)
                    }
                })
                .collect_vec()
        };
        ensure!(
            inputs.iter().all(|p| p.exists()),
            "Some path does not exits"
        );
        inputs
    };

    eprintln!("{}", "Generate par2archive for paths".fg::<Yellow>());

    for p in paths {
        par_sum(&p)
            .with_context(|| format!("Failed to par2 {}", p.display()))?;
    }

    Ok(())
}

fn par_sum(path: &Path) -> Result<()> {
    Ok(())
}
