{ config, pkgs, ... }:

{

    home.packages = with pkgs; [
        file
        ripgrep fd fastfetchMinimal

        libtree
        nix-tree

        rclone
    ];

    home.sessionVariables = {
        NIXPKGS_ALLOW_UNFREE = 1;
    };

}

