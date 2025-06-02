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

    # fonts.fontconfig = {
    #     defaultFonts = lib.mkForce {
    #         sansSerif = [
    #             "Noto Sans"
    #             "Zhudou Sans"
    #             "Source Han Sans SC"
    #         ];
    #         serif = [
    #             "Noto Sans"
    #             "Zhudou Sans"
    #             "Source Han Sans SC"
    #         ];
    #         monospace = [
    #             "Hack"
    #             "Zhudou Sans"
    #             "Source Han Sans SC"
    #         ];
    #     };
    #     localConf = builtins.readFile ./local.xml;
    # };

    systemd.user.tmpfiles.rules = [
        "R! %h/.cache/fontconfig - - - 0 -"
        "R! %h/.var/app/**/cache/fontconfig - - - 0 -"
    ];
}


