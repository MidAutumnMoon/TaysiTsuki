## What This Is

A NixOS config repo. Flake at the root. Machines in `machine/`, shared modules in `nixos/`, custom lib in `tsukilib/`, packages in `packages/`, Rust crates in `rust/`, secrets via sops.

`taysitsuki-convention` skill has more details and rules that are not in here.

## Establish the goal and scope

Use the request and prior discussion to identify what the user truely wants to achieve. Check your interpretation against relevant code, tests, and project conventions. Respect the user's explicit constraints. Turn broad or vague requests into concrete decisions. For brief examples:

- "make the code clearer": identify what obscures the logic, such as mixed responsibilities, confusing names, or tangled control flow.
- "rewrite the comments": decide which explanations to keep, cut, move, or rephrase. Preserve useful rationale and rework awkward sentences.
- "make the edit": establish whether the discussion approved a local change or a general fix.

Trace affected code paths and check related cases for the same underlying problem. Use relevant skills. Include the changes needed for a complete, consistent result within the user's constraints. Leave optional cleanup for a separate task.

Use project conventions for routine choices. Ask a focused question when reasonable interpretations of the request would lead to substantially different changes. State important assumptions behind your approach.

Stop investigating once you can justify the planned changes and explain how to verify them.

## How to Work Here

- To find a machine's config: look in `machine/<name>/`.
- To find a module option: grep in `nixos/` or `tsukilib/`.
- To find a package definition: look in `packages/`, or `rust/` for the Rust crates.
- Secrets are in `sops/`, encrypted. Don't try to read encrypted blobs.
- Don't run `nix flake show`.
- Don't run `nixos-rebuild switch/test` without being asked.
- Use `$CARGO_HOME` instead of `~/.cargo`.

## nixpkgs

Use local nixpkgs if you don't need newer ones.

Run: `nix eval --raw .#flakes.nixpkgs.outPath` to get the path of local nixpkgs in store. Avoid requesting Github over and over again.

## VCS

Use `jj` vcs exclusively. For example, `jj status`, `jj new`.

External pager is configured. Use `jj diff --git` and `jj show --git` for traditional git style diff output.

Don't commit on behalf of the user. Don't write commit message

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
