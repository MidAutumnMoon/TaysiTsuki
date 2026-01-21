{ pkgs, ... }:

{
    programs.niri.enable = true;

    environment.systemPackages = [];

    services.power-profiles-daemon.enable = true;
    services.upower.enable = true;
    hardware.i2c.enable = true;
}
