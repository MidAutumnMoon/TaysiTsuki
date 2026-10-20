---
name: host-system-convention
description: Convention and quirks about the host system. Use this skill autonomously before navigate or operate on the host system.
---

# Host system convention

The host system is NixOS managed with flake: ~/TaysiTsuki.

## Nix

- No legacy `$NIX_PATH`. `nix-shell` won't work. Use flake commands.
- `p` is the correct shorthand that resolves to local nixpkgs. i.e. `nix run p#{name}` instead of `nix run nixpkgs#{name}`.

## Sandbox quirks

- If `/etc` is suspiciously empty, that's probably because of sandbox. Try `/.host-etc` first.
