{ lib, pkgs, config, ... }:

{

    environment.systemPackages = with pkgs; [
        (
            lib.lowPrio ( neovim_teapot.override { treesitter = false; } )
        )
    ];

    environment.sessionVariables = {
        EDITOR = "nvim";
    };

    programs = {
        fish.shellAliases = { "v" = "nvim"; };
        bash.shellAliases = { "v" = "nvim"; };
    };


}

