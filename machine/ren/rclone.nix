{ config, lib, pkgs, ... }:

let

    inherit ( config.sops ) secrets;
    inherit ( config.users.users ) teapot;

in

{

    systemd.tmpfiles.rules = [
        "C /etc/rclone.conf - - - - ${secrets."conf--rclone".path}"
        #"z /etc/rclone.conf 0440 ${teapot.name} ${teapot.group} - -"
        "z /etc/rclone.conf 0440 ${teapot.name} - - -"
    ];

    systemd.services."rclone@" = {
        description = "rclone mount for remote %i";
        serviceConfig = {
            Type = "notify";
            RuntimeDirectory = "rclone";
            ExecSearchPath = "${lib.getBin pkgs.coreutils}/bin";
        };
        serviceConfig.ExecStartPre = ''
            mkdir -pv /mnt/%i
        '';
        # N.B. log to /dev/null because 1.70 regression. Either --log-systemd
        # or not setting log file will cause rclone to hang until service
        # timeout and fail. /dev/stdout is not found when set log-file to it,
        # this might be a hint of the bug?
        serviceConfig.ExecStart = /* bash */ ''
            ${lib.getExe pkgs.rclone} mount \
                --config "/etc/rclone.conf" \
                --log-level "DEBUG" \
                --log-file "/dev/null" \
                --human-readable \
                --use-mmap \
                --cache-dir "%T/rclone_%i" \
                --vfs-cache-mode "full" \
                --vfs-cache-max-size "2G" \
                --vfs-cache-max-age "10m" \
                --dir-cache-time "2m" \
                --poll-interval "1m" \
                --multi-thread-cutoff "128M" \
                --multi-thread-streams "4" \
                --umask "022" \
                --allow-other \
                %i: /mnt/%i
        '';
        # --disable-http2 \
        # serviceConfig.ExecStop = "fusermount -u /mnt/%i";
        environment =
            config.networking.proxy.envVars
            // { GODEBUG = "netdns=go"; };
    };

    systemd.targets."rclone-mounts" = {
        wantedBy = [ "multi-user.target" ];
        wants = [
            "network.target"
            "rclone@Box.service"
        ];
    };

}
