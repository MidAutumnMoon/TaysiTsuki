---
name: taysitsuki-convention
description: Conventions used across TaysiTsuki. Use when working on the monorepo itself.
---

## Flake wiring

- `lib` is nixpkgs lib extended with `tsukilib`, providing `brewNixpkgs` and `brewOS`.
- `packages/` is the overlay adding the `tsuki` package set; `flake.nix` exposes it as `overlays.nuclage = import ./packages { inherit lib flakes; }`.
- `pkgsBrew = lib.brewNixpkgs nixpkgs { config; overlays = [ self.overlays.nuclage ]; }` applies that overlay to nixpkgs for each system; `packages = self.pkgsBrew lib.id` exposes the result as `.#packages.<system>`.
- `nixosConfigurations.<host>` is built by `lib.brewOS` from the same `pkgsBrew` plus shared and machine modules, so every host sees `tsuki.<name>`.
- `packages/tsuki.nix` is not read by the flake; `tsuki.ci-driver` reads it.

## Nix Packaging

### Conventions

- One package per directory: `packages/<name>/package.nix`, exposed as `tsuki.<name>`. Load private siblings via `callPackage ./foo.nix` inside `package.nix`.
- Register cache-worthy packages in `packages/tsuki.nix`; its header documents groups, `tsuki`/`pkgs` constructors, and version tracking.
- Format: 4-space indent, aligned `=`, `|>`/`<|`, `drvSelf:` self-reference, `/*sh*/` before phase strings.

### Patterns

- Rust: ./patterns/rust.md
- Go: ./patterns/go.md
- Binary from GitHub release: ./patterns/github-release.md

### Gotchas

#### Git visibility

Run any `jj` command or `git add` newly created files before nix flake command.

#### Hashes

- Set `cargoHash = "";`, build, then copy the "got:" hash from the error.
- Convert `nix-prefetch-url --unpack` base32 output with `nix hash convert --hash-algo sha256 --to sri` before pasting into `hash`.

#### Update quirks

Use `version.regex` for odd tags, e.g. `app/v(.*)`.
