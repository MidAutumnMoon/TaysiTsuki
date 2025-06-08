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
        fish
        tsuki.neovim

        wezterm

        ( tsuki.kde.drop-down-alike {
            resource_class = "org.wezfurlong.wezterm";
            command = lib.getExe pkgs.wezterm;
            command_args = [ "start" "--cwd" "." "--always-new-process" ];
        } )
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

        "wezterm/wezterm.lua".source =
            mkOutOfStoreSymlink "${dotfiles}/wez/wezterm.lua";

        "mpv/mpv.conf".source =
            mkOutOfStoreSymlink "${dotfiles}/mpv/mpv.conf";

    };

    home.file = {

        ".local/bin".source =
            mkOutOfStoreSymlink "${dotfiles}/bin";

    };

}
