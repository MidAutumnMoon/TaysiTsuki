{ config, lib, pkgs, utils, ... }:

let

    torrentDir =
        config.fileSystems."/srv/torrent".mountPoint;

    torrentDirMountUnit =
        "${utils.escapeSystemdPath torrentDir}.mount";

    fileshareUser =
        config.users.users."fileshare".name;

    ports =
        config.lore.ports;

in

{

    systemd.services."qbittorrent" = {
        description = "qbittorrent daemon";
        after = [
            "network-online.target"
            "nss-lookup.target"
            torrentDirMountUnit
        ];
        wants = [
            "network-online.target"
            torrentDirMountUnit
        ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = rec {
            Type = "simple";
            User = fileshareUser;
            Group = "users";
            AmbientCapabilities = [ "CAP_NET_RAW" ];
            ExecStart = /*bash*/ ''
                "${lib.getExe pkgs.qbittorrent-nox}" \
                    --confirm-legal-notice \
                    --torrenting-port="${toString ports.torrent}" \
                    --webui-port="${toString ports.qbitwebui}" \
                    --profile="${WorkingDirectory}"
            '';
            StateDirectory = "qbittorrent";
            WorkingDirectory = "%S/${StateDirectory}";
            SystemCallFilter = "@system-service";
            ProtectSystem = "strict";
            ProtectHome = true;
            ReadWritePaths = [ torrentDir ];
            MemoryDenyWriteExecute = true;
            RestrictSUIDSGID = true;
            PrivateDevices = true;
            ProtectProc = "invisible";
            ProcSubset = "pid";
        };
    };

    networking.firewall = {
        allowedTCPPorts = [ ports.torrent ];
        allowedUDPPorts = [ ports.torrent ];
    };


    services.caddy.virtualHosts."*.home.lan".extraConfig = ''
        @qbitwebui host qbit.home.lan
        handle @qbitwebui {
            reverse_proxy http://127.0.0.1:${toString ports.qbitwebui}
        }
    '';

}
