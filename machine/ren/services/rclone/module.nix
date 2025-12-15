{ config, lib, pkgs, ... }:

{

    systemd.services."rclone@" = {
        description = "rclone mount for remote %i";
        requires = [ "sops-install-secrets.service" ];
        after = [ "sops-install-secrets.service" ];
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
                --log-level "DEBUG" \
                --log-systemd \
                --human-readable \
                --use-mmap \
                --cache-dir "%T/rclone_%i" \
                --vfs-cache-mode "full" \
                --vfs-cache-max-size "2G" \
                --vfs-cache-max-age "10m" \
                --dir-cache-time "2m" \
                --poll-interval "1m" \
                --multi-thread-cutoff "128M" \
                --multi-thread-streams "8" \
                --umask "022" \
                --disable-http2 \
                --allow-other \
                %i: /mnt/%i
        '';
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
