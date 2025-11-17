{ lib, config, pkgs, ... }:

lib.mkIf config.fonts.fontconfig.enable {

    fonts = {
        enableDefaultPackages = false;
        packages = with pkgs; [
            noto-fonts
            noto-fonts-cjk-sans
            noto-fonts-color-emoji
            # iosevka
            # Monaspace 1.200+ contains nerdfonts natively
            # nerd-fonts.monospace is named "Monaspice" due to legal reasons
            tsuki.monaspace
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
                "Monaspace Argon"
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


