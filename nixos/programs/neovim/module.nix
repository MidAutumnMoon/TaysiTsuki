{ lib, pkgs, config, ... }:

{

    environment.systemPackages = with pkgs; [
        ( lib.lowPrio ( tsuki.neovim.override { withAllTsParsers = false; } ) )
    ];

    environment.sessionVariables = {
        EDITOR = "nvim";
    };

    environment.shellAliases = {
        "v" = "nvim";
    };

}

