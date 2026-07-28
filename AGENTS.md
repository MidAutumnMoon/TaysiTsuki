# AGENTS.md

## What This Is

A NixOS config repo. Flake at the root. Machines in `machine/`, shared modules in `nixos/`, custom lib in `tsukilib/`, packages in `packages/`, secrets via sops.

## Rules

- Do not run `nix flake show` — it evaluates every output and takes forever.
- Do not run `nix build` or `nixos-rebuild` without being asked. They are slow and have side effects.
- When editing Nix files, match the existing style: `=` alignment, `with` at module level, `let`/`in` blocks for local bindings.

## Fitting New Code

- Read the surrounding code before writing. Extend an existing abstraction over
  duplicating; if the new feature doesn't fit, reshape the surrounding code to
  make a place for it rather than force-fitting.
- Reshapes must stay behavior-preserving for other consumers. `nixos/` and
  `tsukilib/` are used by multiple machines - call out any behavior change.
- Don't over-refactor: scale the reshape to the feature.
- No bolt-ons: special-case flags, parallel implementations, copy-paste,
  "refactor later" patches.

## How to Work Here

- To find a machine's config: look in `machine/<name>/` — each is a list of NixOS modules.
- To find a module option: grep in `nixos/` or `tsukilib/`.
- To find a package definition: look in `packages/`.
- Secrets are in `sops/`, encrypted. Don't try to read encrypted blobs.

## Look Things Up

- When unsure about a library, tool, or API, use web search or Context7 before guessing.
- Prefer Context7 for library docs — it pulls real examples and up-to-date signatures.
- Don't hallucinate option names, function signatures, or CLI flags. Look it up.

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

## Communication

- Be concise. Say the thing, stop.
- Don't repeat what I already said or what's already in context.
- Don't pad with disclaimers, summaries, or "hope that helps" type closings.
- If something is wrong, say what's wrong and how to fix it. Don't hedge.

---
