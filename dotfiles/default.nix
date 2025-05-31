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
        _7zz
        par2cmdline-turbo
        jq
    ];

    xdg.configFile = {

        "irb/irbrc".text = /* ruby */ ''
            begin
                require "amazing_print"
                AmazingPrint.irb!
            rescue LoadError
                warn "Can't load amazing_print"
            end
        '';

        "rubocop/config.yml".source =
            mkOutOfStoreSymlink "${tsukiObservatory}/.rubocop.yml";

        "nvim".source =
            mkOutOfStoreSymlink "${dotfiles}/neovim";

        "rclone/rclone.conf".source =
            mkOutOfStoreSymlink "/etc/rclone.conf";

        "gallery-dl/config.json".source =
            mkOutOfStoreSymlink "${dotfiles}/gallery-dl/config.json";

        "atuin/config.toml".source =
            mkOutOfStoreSymlink "${dotfiles}/atuin/config.toml";

    };

    home.file = {

        ".local/bin".source =
            mkOutOfStoreSymlink "${dotfiles}/bin";

    };

}
