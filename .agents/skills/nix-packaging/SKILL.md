---
name: nix-packaging
description: Monorepo conventions and gotchas for adding packages to TaysiTsuki's Nix overlay.
---

# Nix Packaging in TaysiTsuki

Use when adding or updating a package in `packages/`.

## Conventions

- New packages go in `packages/<name>/package.nix`. `packages/default.nix` discovers them automatically; do not register them there.
- Add every cache-worthy package to `packages/tsuki.nix` so CI builds/updates it.
- Reuse existing toolchain helpers when applicable (e.g. `tsuki.rust` for Rust, existing Go builders for Go).
- Match the existing formatting: top-level `=` alignment, module-level `with`, `let`/`in` for locals.

## Few-Shot Patterns

A generic package:

```nix
{
    lib, stdenv, fetchFromGitHub,
    # other deps
}:

stdenv.mkDerivation rec {
    pname = "example";
    version = "1.0.0";
    src = fetchFromGitHub {
        owner = "..."; repo = "..."; tag = "v${version}";
        hash = "sha256-...";
    };
    meta.mainProgram = "example";
}
```

A Rust package uses `tsuki.rust.buildRustPackage` and usually needs `cargoHash` (or `cargoLock`) plus `tsuki.rust.bindgenHook` when vendored C libraries are involved.

Its maintenance entry:

```nix
{ attr = tsuki "example"; group = gs.rust_1; update = {}; }
```

## Gotchas

- **New files must be `git add`ed before Nix sees them.** The flake uses `git+file://`; untracked files are invisible to `nix build`/`nix run`.
- **`cargoHash` placeholder trick.** For Rust packages, start from `sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=` and copy the "got:" hash from the build error.
- **Upstream Rust linker configs.** Some Rust repos force `clang` + `mold` in `.cargo/config.toml`. Strip or override it if linking fails with "cannot find 'ld'".
- **Bindgen crates need `tsuki.rust.bindgenHook`.** If a vendored C dependency panics on "Unable to find libclang", add it.
- **Base32 prefetch output.** `nix-prefetch-url --unpack` returns base32; convert with `nix-hash --to-sri --type sha256 ...` before pasting into `hash`.

Avoid `nix flake show` and `nixos-rebuild` unless explicitly requested.
