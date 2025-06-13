{ config, lib, pkgs, ... }:

{

    systemd.tmpfiles.rules = let
        inherit ( config.sops ) secrets;
        inherit ( config.users.users ) teapot;
    in [
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
        serviceConfig.ExecStart = /* bash */ ''
            ${lib.getExe pkgs.rclone} mount \
                --config "/etc/rclone.conf" \
                --log-level "INFO" \
                --log-systemd \
                --human-readable \
                --use-mmap \
                --cache-dir "/%T/rclone_cache_%i" \
                --vfs-cache-mode "full" \
                --vfs-cache-max-size "2G" \
                --vfs-cache-max-age "10m" \
                --dir-cache-time "2m" \
                --poll-interval "1m" \
                --multi-thread-cutoff "128M" \
                --multi-thread-streams "4" \
                --umask "022" \
                --allow-other \
                --disable-http2 \
                %i: /mnt/%i
        '';
        serviceConfig.ExecStop = "fusermount -u /mnt/Rclone/%i";
        environment = config.networking.proxy.envVars;
    };

    systemd.targets."rclone-mounts" = {
        wantedBy = [ "multi-user.target" ];
        wants = [
            "network.target"
            "rclone@Box.service"
        ];
    };

}
