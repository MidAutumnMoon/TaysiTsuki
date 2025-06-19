{ config, pkgs, ... }:

{

    home.packages = with pkgs; [
        libtree
    ];

    home.sessionVariables = {
        NIXPKGS_ALLOW_UNFREE = 1;
    };

}

