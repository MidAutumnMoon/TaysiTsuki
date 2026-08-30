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

    # Every transient overlay starts before the lifetime coordinator and
    # therefore stops after its ExecStop has finished.
    systemd.user.units."psd-overlay-.service" = {
        overrideStrategy = "asDropin";
        text = ''
            [Unit]
            Before=psd.service
        '';
    };

    # Mount in a prerequisite unit: starting an overlay ordered before the
    # unit whose ExecStart creates it would deadlock the start transaction.
    systemd.user.services."psd-startup" = {
        description = "psd: mount app profiles";

        serviceConfig = {
            Type = "oneshot";
            Slice = "session.slice";
            ExecStart = "${invoke} startup";
            TimeoutStartSec = "30min";
            # fusermount3
            Environment = "PATH=/run/wrappers/bin";
        };
    };

    systemd.user.services."psd" = {
        description = "psd: app profile sync to tmpfs";
        wantedBy = [ "default.target" ];
        requires = [ "psd-startup.service" ];
        after = [ "psd-startup.service" ];

        # Reload the coordinator to reconcile profiles without tearing down
        # healthy mounts during a configuration switch.
        reloadIfChanged = true;

        serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            Slice = "session.slice";
            # Reload and shutdown can wait for a timed resync and copy large
            # profiles.
            TimeoutStartSec = "30min";
            TimeoutStopSec = "30min";
            ExecStart = "${pkgs.coreutils}/bin/true";
            ExecReload = "${invoke} startup";
            # Wait for terminating apps; persist and tear down while every
            # psd-overlay-* service is still live.
            ExecStop = "${invoke} shutdown";
            # fusermount3
            Environment = "PATH=/run/wrappers/bin";
        };
    };

    systemd.user.services."psd-resync" = {
        description = "psd: timed resync";
        after = [ "psd.service" ];

        serviceConfig = {
            Type = "oneshot";
            Slice = "session.slice";
            ExecStart = "${invoke} resync";
            TimeoutStartSec = "30min";
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
