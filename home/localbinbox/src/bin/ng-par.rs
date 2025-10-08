use std::env::current_dir;
use std::path::Path;

use anyhow::Context;
use anyhow::Result;
use anyhow::bail;
use anyhow::ensure;
use ino_color::ceprintln;
use ino_color::fg::Yellow;
use itertools::Itertools;
use localbinbox::collect_read_dir;

fn main() -> Result<()> {
    let paths = {
        let args = std::env::args().skip(1).collect_vec();
        let cwd = current_dir()?;
        let inputs = if args.is_empty() {
            ceprintln!(Yellow, "No files, read current dir");
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

    for p in paths {
        par_sum(&p)
            .with_context(|| format!("Failed to par2 {}", p.display()))?;
    }

    Ok(())
}

fn par_sum(path: &Path) -> Result<()> {
    enum PathType {
        File,
        Dir,
    }

    let path_type = if path.is_file() {
        PathType::File
    } else if path.is_dir() {
        PathType::Dir
    } else {
        bail!("{} is neither file nor dir", path.display())
    };

    ceprintln!(Yellow, "Generate par2archive for {}", path.display());

    Ok(())
}
