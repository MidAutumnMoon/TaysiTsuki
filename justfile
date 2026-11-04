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

[private, group("os")]
nixos_rebuild action host=host:
    nixos-rebuild {{action}} --flake .#{{host}} \
        --elevate=run0 \
        --log-format internal-json \
    |& nom --json

[group("os")]
build host=host: (nixos_rebuild "build" host)

[group("os")]
test host=host: (nixos_rebuild "test" host)

[group("os")]
switch host=host: (nixos_rebuild "switch" host)

#
# Repo maintanence recipes
#

# Commit (only) flake.{nix,lock} with date as commit message
[group("repo")]
commit-flake:
    nu .scripts/commit-flake-update-with-date
