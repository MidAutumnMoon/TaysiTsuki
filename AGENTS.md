# AGENTS.md

## What This Is

A NixOS config repo. Flake at the root. Machines in `machine/`, shared modules in `nixos/`, custom lib in `tsukilib/`, packages in `packages/`, secrets via sops.

## Rules

- Do not run `nix flake show` — it evaluates every output and takes forever.
- Do not run `nix build` or `nixos-rebuild` without being asked. They are slow and have side effects.
- When editing Nix files, match the existing style: `=` alignment, `with` at module level, `let`/`in` blocks for local bindings.

## No `| tail`/` or head`

Do not pipe any command output through `head` or `tail`, tools will properly handle large output natively.

## Fitting New Code

- Recover the domain truth before choosing a shape: valid states, natural owner, boundaries, and relevant failure or resource constraints.
- Give each fact one authoritative home. Prefer representations and APIs that enforce invariants over comments or caller discipline.
- Read the surrounding code first. Extend an abstraction only when the new behavior shares its policy and ownership; otherwise reshape proportionally instead of adding special cases, parallel paths, or copied logic.
- Keep dependencies and data flow explicit. Do not recover required context from ambient state or reconstruct information discarded earlier.
- Design for real pressures, not hypothetical reuse. Preserve existing behavior unless a change is requested; consolidate experiments before landing.

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
