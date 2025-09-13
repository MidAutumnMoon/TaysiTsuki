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
            SystemCallFilter = "@system-service";
            AmbientCapabilities = [ "CAP_NET_RAW" ];
            ReadWritePaths = [ downloadDir ];
            UMask = lib.mkForce "0007";
        };
        useHardening = true;
    };

    networking.firewall = {
        allowedTCPPorts = [ ports.torrent ];
        allowedUDPPorts = [ ports.torrent ];
    };

    services.caddy.virtualHosts."im_418".extraConfig =
        let
            inherit (apps.tailnet) downloader_dashboard;
            inherit (apps.public) torrent_download;
        in
        ''
            @qbitwebui {
                host ${downloader_dashboard.fqdn}
                client_ip private_ranges
            }
            handle @qbitwebui {
                reverse_proxy http://localhost:${toString ports.qbitwebui}
            }

            @torrent_download host ${torrent_download.fqdn}
            handle @torrent_download {
                basic_auth {
                    {env.DOWNLOAD_AUTH_NAME} {env.DOWNLOAD_AUTH_PASSWD}
                }
                root * ${downloadDir}
                file_server {
                    browse {
                        sort size desc
                    }
                }
            }
        '';

    sops.secrets = {
        "basicauth_name".sopsFile = ./cred--basicauth.sops.yml;
        "basicauth_passwd".sopsFile = ./cred--basicauth.sops.yml;
    };

    sops.templates."download-auth-creds".content =
        let
            inherit (config.sops.placeholder)
                basicauth_name basicauth_passwd;
        in
        ''
            DOWNLOAD_AUTH_NAME=${basicauth_name}
            DOWNLOAD_AUTH_PASSWD=${basicauth_passwd}
        '';

    systemd.services.caddy = {
        serviceConfig = {
            EnvironmentFile =
                config.sops.templates."download-auth-creds".path;
            SupplementaryGroups = [ groupsCfg.qbit.name ];
        };
    };
}
