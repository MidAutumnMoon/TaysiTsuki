{ lib, ... }:

{

    imports = [
        ./implementation-fish
        ./fish.nix
    ];

    environment.shellAliases = {
        "ll" = null;
        "-" = "cd -";
    };

    programs.command-not-found.enable = lib.mkForce false;

}
