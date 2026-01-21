{ dots, pkgs, ... }:

{

    # ref: https://gist.github.com/linhusp/05f8f7e0af3fa0fbb944dec17a75aa78
    packages = with pkgs; [
        kdePackages.dolphin
        kdePackages.dolphin-plugins
        kdePackages.ffmpegthumbs
        kdePackages.kded
        kdePackages.qt6ct
        kdePackages.kservice
        ffmpegthumbnailer
    ];

    envvars = {
        XDG_MENU_PREFIX = "plasma-";
        QT_QPA_PLATFORM = "wayland";
        QT_QPA_PLATFORMTHEME = "qt6ct";
        QT_QPA_PLATFORMTHEME_QT6 = "qt6ct";
        GTK_DECORATION_LAYOUT = "";
    };

    xdg_config."niri".src = dots.get "niri";

    xdg_config."systemd/user/niri.service.d/override.conf".text = ''
        [Unit]
        Wants = noctalia.service
    '';

}
