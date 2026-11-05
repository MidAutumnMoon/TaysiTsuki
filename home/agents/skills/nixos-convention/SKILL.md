---
name: nixos-convention
description: Convention and quirks about the host system. Use this skill autonomously before navigate or operate on the host system, or you need missing programs.
---

The host system is NixOS managed with flake: ~/TaysiTsuki.

## Nix

- Use `nix shell` or other nix flake commands for missing programs.
- No legacy `$NIX_PATH`. `nix-shell` won't work. Use flake commands.

## Sandbox quirks

- If `/etc` is suspiciously empty, that's probably because of sandbox. Try `/.host-etc` first.
