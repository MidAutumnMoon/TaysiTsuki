use std::env::current_dir;
use std::path::Path;

use anyhow::Result;
use ino_color::InoColor;
use ino_color::fg::Yellow;
use itertools::Itertools;
use localbinbox::collect_read_dir;

fn main() -> Result<()> {
    println!("Hello, world!");

    let inputs = {
        let args = std::env::args().skip(1).collect_vec();
        dbg!(&args);
        if args.is_empty() {
            eprintln!("{}", "No files, read current dir".fg::<Yellow>());
            collect_read_dir(&current_dir()?)?
        } else {
            //
            eprintln!("iera");
            todo!()
        }
    };

    Ok(())
}

fn par(path: &Path) -> Result<()> {
    Ok(())
}
