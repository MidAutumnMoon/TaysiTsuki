{ pkgs, lib, ... }:

{

    services.displayManager.sddm = {
        enable = true;
        wayland.enable = true;
        wayland.compositor = "kwin";
        settings.General.DisplayServer = "wayland";
    };

    services.desktopManager.plasma6.enable = true;

    environment.plasma6.excludePackages =
        with pkgs.kdePackages; [
            elisa
            krdp
            kwin-x11
            khelpcenter
            discover
            gwenview
            (lib.getBin qttools)
        ];

    programs.kde-pim.enable = false;

    i18n.inputMethod = {
        enable = true;
        type = "fcitx5";
        fcitx5 = {
            addons = with pkgs; [
                fcitx5-mozc
                kdePackages.fcitx5-chinese-addons
            ];
            waylandFrontend = true;
        };
    };

    services.orca.enable = false;
    services.geoclue2.enable = false;
    services.fwupd.enable = false;
    services.speechd.enable = false;

}
