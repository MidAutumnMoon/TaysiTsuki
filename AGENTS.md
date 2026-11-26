# TaysiTsuki

A NixOS config repo. Flake at the root. Machines in `machine/`, shared modules in `nixos/`, custom lib in `tsukilib/`, packages in `packages/`, Rust crates in `rust/`, secrets via sops.

`taysitsuki-convention` skill has more details and rules that are not in here.

## How to Work Here

- To find a machine's config: look in `machine/<name>/`.
- To find a module option: grep in `nixos/` or `tsukilib/`.
- To find a package definition: look in `packages/`, or `rust/` for the Rust crates.
- Secrets are in `sops/`, encrypted. Don't try to read encrypted blobs.
- Don't run `nix flake show`.
- Don't run `nixos-rebuild switch/test` without being asked.

## nixpkgs

Use local nixpkgs if you don't need newer ones.

Run: `nix eval --raw .#flakes.nixpkgs.outPath` to get the path of local nixpkgs in store. Avoid requesting Github over and over again.

## VCS

Use `jj` vcs exclusively. For example, `jj status`, `jj new`. Don't commit on behalf of the user without permission.

## Dotfile modules (`home/*/module.nix`)

Each `home/<name>/module.nix` is a lny submodule config (not a NixOS module),
consumed by `nixos/users/lny`. Returns an attrset of lny options:

- `packages` — packages added to user profile
- `xdg_config."<path>".src/.text` — symlink: $XDG_CONFIG_HOME/<path>
- `home."<path>".src/.text` — symlink: $HOME/<path>
- `envvars` — environment vars (via environment.d)

The attrname is the _destination_; `.src`/`.text` is the _source_.

`dots` (defined in `home/module.nix`) is a module arg:

- `dots.get "<path>"` → `{{ home }}/TaysiTsuki/home/<path>`
- `{{ home }}` / `{{ config }}` are jinja templates expanded at activation by
  the lny binary (see `nixos/users/lny`), avoiding home-manager round trips.
