---
name: nix-packaging
description: Monorepo conventions and gotchas for adding packages to TaysiTsuki's Nix overlay.
---

# Nix Packaging in TaysiTsuki

Use when adding or updating a package in `packages/`.

## Conventions

- One package per directory: `packages/<name>/package.nix`, auto-exposed as
  `tsuki.<name>`. No registration needed. Other files in the dir are private —
  load them with `callPackage ./foo.nix` inside `package.nix` if needed.
- Depend on other repo packages through the `tsuki` argument:
  `{ tsuki }: tsuki.rust.buildRustPackage ...`.
- Register cache-worthy packages in `packages/tsuki.nix`:
  - `group` (`go_1`, `go_2`, `rust_1`, `rust_2`, `small_1`) only splits CI build
    jobs — pick a fitting one.
  - `update = {}` opts into scheduled `nix-update`; omit it for repo-pinned
    versions (workspace crates, flake inputs). Further knobs when needed:
    `version_regex`, `unstable_branch`, `preview_release`, `pinned`, `subpackages`.
- Unstable branches version as `0-unstable-YYYY-MM-DD`. Tests off by default
  (`doCheck = false`).
- Style: 4-space indent, aligned `=`, pipe operators (`|>`, `<|`) from latest nix, `drvSelf:`
  argument for self-reference, `/*sh*/` before phase strings.

## Patterns

Upstream Rust — always `tsuki.rust` (rust-overlay toolchain), never nixpkgs
`rustPlatform`; static builds via `pkgsStatic.tsuki.rust`:

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

Rust crate from this repo's Cargo workspace:

```nix
{ tsuki }:

tsuki.rust.buildRustPackage rec {
    pname = "my-crate";
    version = "0.1.0";
    inherit (tsuki.workspace) src cargoLock;
    cargoBuildFlags = "-p ${pname}";
    doCheck = false;
}
```

Prebuilt GitHub-release binary — `stdenv.mkDerivation` + `autoPatchelfHook`
(`stdenv.cc.cc.lib` in `buildInputs` for glibc-linked binaries):

```nix
src = tsuki.fetchGitHubRelease {
    owner = "..."; repo = "..."; tag = "v${version}";
    file = "example-linux-x86_64.tar.gz";
    hash = "sha256-...";
};
```

Go — plain nixpkgs `buildGoModule` + `vendorHash`; conventionally
`env.CGO_ENABLED = 0` and `env.GOAMD64 = "v3"`.

## Gotchas

### Git visibility

- **New files must be `git add`ed before Nix sees them** — the flake is a
  `git+file` tree; untracked files are invisible to `nix build`/`nix run`.
- **`tsuki.workspace` src is `gitTracked` ∩ workspace files** — untracked crate
  sources silently fall out of the build input.

### Hashes

- **`cargoHash` placeholder trick** — start from
  `sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=`, copy the "got:" hash
  from the build error.
- **`nix-prefetch-url --unpack` returns base32** — convert with
  `nix-hash --to-sri --type sha256` before pasting into `hash`.

### Rust builds

- **Bindgen crates need `tsuki.rust.bindgenHook`** — vendored C dependency
  panicking on "Unable to find libclang" → add to `nativeBuildInputs`.
- **Upstream `.cargo/config.toml` linker configs** (forced `clang`+`mold`) break
  the stdenv linker ("cannot find 'ld'") — strip via `postPatch`.

### Update quirks

- **Odd tags need `version_regex`** — `hysteria` (`app/v(.*)`), `playwright-cli`
  (deprecated stub tags sort above real ones; pinned to `v(0\.1\..*)`).
