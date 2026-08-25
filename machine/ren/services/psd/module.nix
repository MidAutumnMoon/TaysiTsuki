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

    # The live profile set is not reconciled across reloads. Before changing
    # this list or Firefox profile discovery, close the affected apps and run
    # `psd unsync`, or log out so the current session is checkpointed first.

    # Common invocation prefix.
    invoke = "${lib.getExe psd} --config ${configFile}";

in {

    environment.systemPackages = [ psd ];
    programs.fuse.enable = true;

    systemd.user.services."psd" = {
        description = "psd: app profile sync to tmpfs";
        wantedBy = [ "default.target" ];
        # Login commonly launches Firefox immediately. Persistence starts
        # from the timer only, after the profile has had time to settle.

        # Overlay daemons run as independent transient user services. Reload
        # this coordinator rather than tearing down healthy mounts.
        reloadIfChanged = true;

        serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            # Startup, reload, and unsync can all wait for a timed resync and
            # copy large profiles.
            TimeoutStartSec = "10min";
            TimeoutStopSec = "10min";
            ExecStart = "${invoke} startup";
            # Persistence runs in psd-resync.service so a copy failure cannot
            # tear down healthy mounts. Stop only checkpoints; explicit
            # `psd unsync` owns destructive teardown.
            ExecReload = "${invoke} startup";
            ExecStop = "${invoke} resync";
            # fusermount3
            Environment = "PATH=/run/wrappers/bin";
        };
    };

    systemd.user.services."psd-resync" = {
        description = "psd: timed resync";
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
            # First checkpoint is five minutes after login; wait thirty
            # minutes after each completed attempt before trying again.
            OnActiveSec = "5min";
            OnUnitInactiveSec = "30min";
        };
    };
}
