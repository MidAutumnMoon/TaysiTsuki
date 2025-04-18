{ lib, ... }:

{

    imports = [
        ./implementation-fish
        ./fish.nix
    ];

    environment.shellAliases = {
        "ll" = null;
    };

    programs.command-not-found.enable = lib.mkForce false;

}
