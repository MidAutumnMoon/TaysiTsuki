Use `tsuki.rust` (rust-overlay toolchain) for upstream Rust.

```nix
{ lib, stdenv, fetchFromGitHub, tsuki }:

tsuki.rust.buildRustPackage (drvSelf: {
    pname = "example";
    version = "1.2.3";

    src = fetchFromGitHub {
        owner = "..."; repo = "...";
        tag = "v${drvSelf.version}";
        hash = "sha256-...";
    };
    cargoHash = "sha256-...";
    doCheck = false;
    RUSTFLAGS = with stdenv;
        lib.optional hostPlatform.isx86_64 "-Ctarget-cpu=x86-64-v3";
})
```