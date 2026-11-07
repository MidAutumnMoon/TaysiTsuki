---
name: nixos-convention
description: Convention and quirks about the host system. Use this skill autonomously before you navigate or operate on the host system, or when you need missing programs.
---

The host system is NixOS managed with flake: ~/TaysiTsuki.

## Nix

- Use `nix shell` or other nix flake commands for missing programs. MUST NOT run `nix profile add`.
- No legacy `$NIX_PATH`. `nix-shell` won't work. MUST use flake based commands.

## Sandbox quirks

- If `/etc` is suspiciously empty, that's probably because of the sandbox. Try `/.host-etc` first.

## Python

MUST use `uv`. Python isn't globally installed. Prefer self-contained scripts, MUST NOT pip install globally.
