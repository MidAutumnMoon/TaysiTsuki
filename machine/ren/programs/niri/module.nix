{ pkgs, lib, ... }:

{
    programs.niri.enable = true;
    programs.niri.useNautilus = false;

    environment.systemPackages = with pkgs; [
        kdePackages.breeze
        kdePackages.breeze-icons
        kdePackages.breeze-gtk
        nwg-look
        adwaita-icon-theme
    ];

    services.power-profiles-daemon.enable = true;
    services.upower.enable = true;
    hardware.i2c.enable = true;

    xdg.portal = {
        extraPortals = [ pkgs.kdePackages.xdg-desktop-portal-kde ];
        config.niri = {
            "org.freedesktop.impl.portal.FileChooser" = lib.mkForce "kde";
        };
    };

    # ref: https://github.com/NixOS/nixpkgs/issues/409986
    environment.etc."xdg/menus/applications.menu".source =
        "${pkgs.kdePackages.plasma-workspace}/etc/xdg/menus/plasma-applications.menu";
}
