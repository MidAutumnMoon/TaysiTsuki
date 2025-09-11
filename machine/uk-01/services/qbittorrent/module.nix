{ config, lib, pkgs, ... }:

let

    inherit ( config ) lore;
    inherit ( lore ) ports apps;

    downloadDir = "/srv/download";

    usersCfg = config.users.users;
    groupsCfg = config.users.groups;

in {

    users = {
        users."qbit" = {
            group = groupsCfg.qbit.name;
            isSystemUser = true;
        };
        groups."qbit" = {};
    };

    systemd.services."mkdir-torrent" = {
        unitConfig = {
            ConditionPathExists = "!${downloadDir}";
        };
        serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
        };
        script = ''
            mkdir -pv -m 0755 ${downloadDir}
            chown -R \
                ${usersCfg.qbit.name}:${groupsCfg.qbit.name} \
                ${downloadDir}
        '';
    };

    systemd.services."qbittorrent" = {
        description = "qbittorrent daemon";
        after = [
            "network-online.target"
            "nss-lookup.target"
            "mkdir-torrent.service"
        ];
        requires = [ "mkdir-torrent.service" ];
        wants = [ "network-online.target" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = rec {
            Type = "simple";
            User = usersCfg.qbit.name;
            Group = groupsCfg.qbit.name;
            ExecStart = ''
                "${lib.getExe pkgs.qbittorrent-nox}" \
                    --confirm-legal-notice \
                    --torrenting-port="${toString ports.torrent}" \
                    --webui-port="${toString ports.qbitwebui}" \
                    --profile="${WorkingDirectory}"
            '';
            StateDirectory = "qbittorrent";
            WorkingDirectory = "%S/${StateDirectory}";
            SystemCallFilter = "@system-service ~@privileged";
            AmbientCapabilities = [ "CAP_NET_RAW" ];
            ReadWritePaths = [ downloadDir ];
        };
        useHardening = true;
    };

    networking.firewall = {
        allowedTCPPorts = [ ports.torrent ];
        allowedUDPPorts = [ ports.torrent ];
    };

    services.caddy.virtualHosts."im_418".extraConfig =
        let inherit (apps.tailnet) downloader_dashboard; in
        ''
            @qbitwebui host ${downloader_dashboard.fqdn}
            handle @qbitwebui {
                reverse_proxy http://localhost:${toString ports.qbitwebui}
            }
        '';

}
