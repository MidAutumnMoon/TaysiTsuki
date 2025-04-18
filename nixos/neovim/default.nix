{ lib, pkgs, config, ... }:

{

    environment.systemPackages = with pkgs; [
        ( lib.lowPrio ( neovim_teapot.override { withAllTsParsers = false; } ) )
    ];

    environment.sessionVariables = {
        EDITOR = "nvim";
    };

    environment.shellAliases = {
        "v" = "nvim";
    };

}

