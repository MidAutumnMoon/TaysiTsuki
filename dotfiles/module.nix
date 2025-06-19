{ config, pkgs, nixosConfig, ... }:

let

    inherit ( config.lib.file )
        mkOutOfStoreSymlink
    ;

    inherit ( nixosConfig.lore )
        tsukiObservatory
    ;

    dotfiles = "${tsukiObservatory}/dotfiles";

in {

    home.packages = with pkgs; [
        fish
    ];

    xdg.configFile = {

        "atuin/config.toml".source =
            mkOutOfStoreSymlink "${dotfiles}/atuin/config.toml";

    };

}
