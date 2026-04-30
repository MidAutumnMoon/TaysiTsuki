# AGENTS.md

## What This Is

A NixOS config repo. Flake at the root. Machines in `machine/`, shared modules in `nixos/`, custom lib in `tsukilib/`, packages in `packages/`, secrets via sops.

## Rules

- Do not run `nix flake show` — it evaluates every output and takes forever.
- Do not run `nix build` or `nixos-rebuild` without being asked. They are slow and have side effects.
- When editing Nix files, match the existing style: `=` alignment, `with` at module level, `let`/`in` blocks for local bindings.

## How to Work Here

- To find a machine's config: look in `machine/<name>/` — each is a list of NixOS modules.
- To find a module option: grep in `nixos/` or `tsukilib/`.
- To find a package definition: look in `packages/`.
- Secrets are in `sops/`, encrypted. Don't try to read encrypted blobs.

## Look Things Up

- When unsure about a library, tool, or API, use web search or Context7 before guessing.
- Prefer Context7 for library docs — it pulls real examples and up-to-date signatures.
- Don't hallucinate option names, function signatures, or CLI flags. Look it up.

## Complex Tasks

- Break large tasks into sub-tasks. Tackle them in parallel with sub-agents when they don't depend on each other.
- Give each sub-agent full context — it won't see your conversation history.
- Keep sub-tasks scoped to one concern. If two sub-agents might edit the same file, don't run them in parallel.

## Communication

- Be short. Say the thing, stop.
- Don't repeat what I already said or what's already in context.
- Don't pad with disclaimers, summaries, or "hope that helps" type closings.
- If something is wrong, say what's wrong and how to fix it. Don't hedge.

---
