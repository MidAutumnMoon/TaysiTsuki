set lazy

host := `hostname`

[private, default]
default:
    @just --list --list-prefix "" --list-heading ""

#
# NixOS management recipes
#

[group("os")]
repl host=host:
    nix repl .#nixosConfigurations.{{host}}

[group("os")]
build host=host:
    nu .scripts/nixos-rebuild-with-diff build {{host}}

[group("os")]
test host=host:
    nu .scripts/nixos-rebuild-with-diff test {{host}}

[group("os")]
switch host=host:
    nu .scripts/nixos-rebuild-with-diff switch {{host}}

[group("os")]
boot host=host:
    nu .scripts/nixos-rebuild-with-diff boot {{host}}

# Show all live gc roots
[group("os")]
gc-roots-show:
    nix-store --gc --print-roots | rg --invert-match ^\"/proc

#
# Repo maintanence recipes
#

# Commit (only) flake.{nix,lock} with date as commit message
[group("repo")]
commit-flake:
    nu .scripts/commit-flake-update-with-date
