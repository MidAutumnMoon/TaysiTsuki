# profile-sync-daemon

{ pkgs, ... }:

{

    systemd.packages = [ pkgs.tsuki.profile-sync-daemon ];
    environment.systemPackages = [ pkgs.tsuki.profile-sync-daemon ];

    systemd.user.services.psd = {
        # wantedBy = [ "default.target" ];
        wantedBy = [ "graphical-session.target" ];
    };
    systemd.user.timers.psd-resync = {
        wantedBy = [ "timers.target" ];
    };
}
