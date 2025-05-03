{ config, pkgs, ... }:

let

    inherit ( config.home )
        homeDirectory
    ;

in {

    home.packages = with pkgs; [
        file
        ripgrep fd fastfetchMinimal

        libtree
        nix-tree

        rclone
    ];

    home.sessionVariables = {

        NIXPKGS_ALLOW_UNFREE = 1;

        Nuran = config.lore.nuranDirPath;

    };

}

