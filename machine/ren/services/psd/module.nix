# psd: app profile sync to tmpfs via overlayfs
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
        description = "psd: app profile sync to tmpfs";
        wantedBy = [ "default.target" ];
        # Initial persistence is a separate unit: a live profile may change
        # while rsync scans it, but that must never fail the mount-owning
        # service and kill its fuse-overlayfs daemons.
        wants = [ "psd-resync.service" ];
        before = [ "psd-resync.service" ];

        # fuse-overlayfs daemons stay in this unit's cgroup. Restarting the
        # unit would kill every mount after ExecStop, so apply switch-time
        # updates through the idempotent startup path instead.
        reloadIfChanged = true;

        serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            # Startup, reload, and unsync can all wait for a timed resync and
            # copy large profiles.
            TimeoutStartSec = "10min";
            TimeoutStopSec = "10min";
            ExecStart = "${invoke} startup";
            # Initial and periodic persistence run in psd-resync.service so a
            # copy failure cannot tear down healthy mounts.
            ExecReload = "${invoke} startup";
            ExecStop = "${invoke} unsync";
            # fusermount3
            Environment = "PATH=/run/wrappers/bin";
        };
    };

    systemd.user.services."psd-resync" = {
        description = "psd: timed resync";
        requires = [ "psd.service" ];
        after = [ "psd.service" ];

        serviceConfig = {
            Type = "oneshot";
            ExecStart = "${invoke} resync";
            TimeoutStartSec = "10min";
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
