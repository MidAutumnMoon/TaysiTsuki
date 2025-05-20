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
            ExecStart = /*bash*/ ''
                "${lib.getExe pkgs.qbittorrent-nox}" \
                    --confirm-legal-notice \
                    --torrenting-port="${toString ports.torrent}" \
                    --webui-port="${toString ports.qbitwebui}" \
                    --profile="${WorkingDirectory}"
            '';
            StateDirectory = "qbittorrent";
            WorkingDirectory = "%S/${StateDirectory}";
            SystemCallFilter = "@system-service ~@privileged";
            ProtectSystem = "strict";
            ProtectHome = true;
            ReadWritePaths = [ torrentDir ];
            MemoryDenyWriteExecute = true;
            RestrictSUIDSGID = true;
            PrivateDevices = true;
            ProtectProc = "invisible";
            ProcSubset = "pid";
            RemoveIPC = true;
            NoNewPrivileges = true;
            ProtectClock = true;
            ProtectControlGroups = true;
            ProtectKernelLogs = true;
            ProtectKernelTunables = true;
            ProtectHostname = true;
            LockPersonality = true;
            SystemCallArchitectures = "native";
            RestrictNamespaces = true;
            CapabilityBoundingSet = "";
            AmbientCapabilities = [ "CAP_NET_RAW" ];
        };
    };

    networking.firewall = {
        allowedTCPPorts = [ ports.torrent ];
        allowedUDPPorts = [ ports.torrent ];
    };

    services.caddy.virtualHosts."*.home.lan".extraConfig = ''
        @qbitwebui host qbit.home.lan
        handle @qbitwebui {
            handle /api* {
                reverse_proxy http://127.0.0.1:${toString ports.qbitwebui}
            }
            root * ${pkgs.tsuki.vuetorrent}
            file_server
        }
    '';

    systemd.services."empty-torrent-recycle-bin" = {
        description = "Empty ${torrentDir} recycle bin";
        script = /* bash */ ''
            declare -r RecycleBin="${torrentDir}/.recycle"
            declare -r EmptyDir="$( mktemp -d )"
            echo "Start empty recycle bin"
            if [[ -d "$RecycleBin" ]]; then
                # N.B. / after dirs
                rsync -rvP --delete "$EmptyDir/" "$RecycleBin/"
            fi
            echo "Finish empty recycle bin"
        '';
        startAt = "daily";
        path = [ pkgs.rsync ];
    };

    systemd.timers."empty-torrent-recycle-bin" = {
        timerConfig.Persistent = true;
    };

}
