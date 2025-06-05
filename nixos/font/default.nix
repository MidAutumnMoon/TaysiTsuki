{ lib, config, pkgs, ... }:

let

in

lib.mkIf config.fonts.fontconfig.enable {

    fonts = {
        enableDefaultPackages = false;
        packages = with pkgs; [
            noto-fonts
            noto-fonts-cjk-sans
            noto-fonts-color-emoji
            nerd-fonts.iosevka
            nerd-fonts.monaspace
        ];
    };

    fonts.fontconfig = {
        defaultFonts = {
            serif = [
                "Noto Serif"
                "Noto Color Emoji"
            ];
            sansSerif = [
                "Noto Sans"
                "Noto Color Emoji"
            ];
            monospace = [
                "Iosevka Nerd Font"
                "Iosevka"
                "Noto Color Emoji"
            ];
        };
        localConf = builtins.readFile ./local.xml;
        useEmbeddedBitmaps = true;
    };

    systemd.user.tmpfiles.rules = [
        "R! %h/.cache/fontconfig - - - 0 -"
        "R! %h/.var/app/**/cache/fontconfig - - - 0 -"
    ];
}


