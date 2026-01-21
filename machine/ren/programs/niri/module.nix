{ pkgs, ... }:

{
    programs.niri.enable = true;

    environment.systemPackages = with pkgs; [
        kdePackages.qt6ct
        kdePackages.breeze
        kdePackages.breeze-icons
        nwg-look
        adwaita-icon-theme
    ];

    services.power-profiles-daemon.enable = true;
    services.upower.enable = true;
    hardware.i2c.enable = true;
}
