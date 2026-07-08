# Architecture Notes

Design tensions and open questions about this flake's structure.
This is a reference, not a roadmap — choices documented here may stay as-is.

---

## The inheritance model

`nixos/` is the general tier; `machine/` is the specific tier. Modules are
auto-discovered by `listAllModules`, not explicitly imported. This is an
**inheritance** model, not a **composition** model:

- Shared modules apply to all machines unconditionally.
- Machine modules cannot be reused across machines.
- There is no middle tier between "all machines" and "one machine."

This is a deliberate trade-off. The cost is that the dependency graph between
machines and modules is implicit — it lives in the directory structure, not in
any `imports` list. The benefit is that adding a machine or a shared module
requires zero wiring.

### Consequence: the `mkIf` guard pattern

Because every shared module is always imported, modules that should be optional
guard themselves with `mkIf config.services.<x>.enable`. This works for
upstream NixOS services (which have `.enable` options), but has rough edges:

- Modules that don't map to a single upstream service need ad-hoc guards or
  custom enable options.
- Cross-module config (e.g., a machine module writing into a shared module's
  `virtualHosts`) relies on merge semantics and has no explicit declaration of
  "this machine depends on caddy being configured."

### Consequence: no shared "optional" tier

If two machines want the same service configured the same way, the config must
either live in `nixos/` (applies to *all* machines, needs a guard) or be
duplicated per machine. There is no "apply to these N machines" mechanism
short of hostname checks.

---

## Why modules mirror the NixOS option tree

An earlier version grouped modules by *feature* (e.g., a `desktop/` bundle, a
`network/` bundle). This was abandoned because it produced a confusing option
structure: a single feature module would set `config.boot`, `config.services`,
`config.networking`, and `config.programs` simultaneously, making it hard to
find what touched what.

Mirroring the NixOS option namespace (`boot/`, `networking/`, `services/`) won
because each module maps cleanly to the options it sets. The trade-off is that
a single *concern* (e.g., "the proxy stack") gets fragmented across several
directories.

---

## Open question: where do machine-scoped shared things live?

The inheritance model creates an ambiguity for things that are:
- shared across *some* machines (not all), but
- not machine-specific (not belonging to one `machine/<n>/`).

Secrets are the current example (see below), but the pattern generalizes to
any config that is "common to a subset of machines."

The options within the current architecture:
- Put it in `nixos/` with a hostname guard (what `sops/module.nix` does).
- Duplicate it per machine.
- Introduce a new tier (rejects the two-tier inheritance model).

There is no clean answer within the current model. This is the most live
architectural tension.

---

## Secrets: a symptom of the subset problem

Secrets are currently split across three locations, none of which is clearly
the "right" one:

- `sops/module.nix` — shared secrets + per-machine blocks guarded by hostname.
- `machine/<n>/sops/module.nix` — machine-local key material and seed secrets.
- `nixos/sops/module.nix` — a shared secret (cloudflare token) that overlaps
  with `sops/`.

The split exists because the inheritance model has no native concept of
"secrets for a subset of machines." The hostname-guard helper in
`sops/module.nix` is a workaround, and the `nixos/sops/` duplication suggests
the boundary between "shared secret" and "machine secret" is unclear.
