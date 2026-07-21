# psd: browser profile sync to tmpfs via overlayfs
#
# Config is generated from this module and passed via --config;
# no user-home file management needed.

{ lib, pkgs, ... }:

let

    psd = pkgs.tsuki.psd-rs;

    # Generated config, passed via --config.
    configFile = pkgs.writeText "psd-config.json"
        (builtins.toJSON {
            apps = [ "firefox" "telegram" "cherrystudio" ];
        });

    # Common invocation prefix.
    invoke = "${lib.getExe psd} --config ${configFile}";

in {

    environment.systemPackages = [ psd ];
    programs.fuse.enable = true;

    systemd.user.services."psd" = {
        description = "psd: browser profile sync to tmpfs";
        wantedBy = [ "default.target" ];

        serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            # Give unsync time to finish the rsync merge. psd v7 was
            # killed by the 90s default, causing "always ungraceful"
            # on every reboot.
            TimeoutStopSec = "10min";
            ExecStart = "${invoke} startup";
            ExecStartPost = "${invoke} resync";
            ExecStop = "${invoke} unsync";
            # fusermount3
            Environment = "PATH=/run/wrappers/bin";
        };
    };

    systemd.user.services."psd-resync" = {
        description = "psd: timed resync";

        serviceConfig = {
            Type = "oneshot";
            ExecStart = "${invoke} resync";
            Environment = "PATH=/run/wrappers/bin";
        };
    };

    systemd.user.timers."psd-resync" = {
        description = "psd: resync timer";
        wantedBy = [ "timers.target" ];

        timerConfig = {
            OnCalendar = "*:0/30";
            Persistent = true;
        };
    };
}
