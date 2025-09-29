use std::str::FromStr;

use serde::Deserialize;

#[derive(Debug)]
pub struct Manifest {
    packages: Vec<Package>,
}

impl FromStr for Manifest {
    type Err = anyhow::Error;
    fn from_str(input: &str) -> Result<Self, Self::Err> {
        todo!()
    }
}

#[derive(Debug)]
#[derive(Deserialize)]
pub struct Package {
    attr: String,
    group: String,
    ver_regex: Option<String>,
    unstable: Option<bool>,
}
