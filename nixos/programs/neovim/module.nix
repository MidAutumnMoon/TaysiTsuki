{ pkgs, ... }:

{

    environment.systemPackages = with pkgs; [ tsuki.neovim ];

    environment.sessionVariables = {
        EDITOR = "nvim";
    };

    environment.shellAliases = {
        "v" = "nvim";
    };

}

