{ config, lib, pkgs, ... }:

{

    systemd.services."rclone-box" = {
        description = "rclone mount for storage box";
        requires = [
            "sops-install-secrets.service"
        ];
        after = [
            "sops-install-secrets.service"
        ];
        serviceConfig = {
            Type = "notify";
            RuntimeDirectory = "rclone";
        };
        serviceConfig.ExecStartPre =
            "${lib.getExe' pkgs.coreutils "mkdir"} -pv /mnt/Box";
        serviceConfig.ExecStart = lib.concatStringsSep " " [
            "${lib.getExe pkgs.rclone}"
            "mount"
            "--config" "/etc/rclone.conf"
            "--log-level" "DEBUG"
            "--log-systemd"
            "--human-readable"
            "--use-mmap"
            "--cache-dir" "%T/rclone_box"
            "--vfs-cache-mode" "full"
            "--vfs-cache-max-size" "2G"
            "--vfs-cache-max-age" "10m"
            "--dir-cache-time" "2m"
            "--poll-interval" "1m"
            "--multi-thread-cutoff" "128M"
            "--multi-thread-streams" "8"
            "--umask" "022"
            # "--disable-http2"
            "--allow-other"
            "Box: /mnt/Box"
        ];
        environment =
            config.networking.proxy.envVars
            // { GODEBUG = "netdns=go"; };
        wantedBy = [ "multi-user.target" ];
    };

}
