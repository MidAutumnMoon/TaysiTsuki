{ config, ... }:

let

    inherit (config) lore;
    inherit (lore) ports apps;

    downloadDir = "/srv/download";

in {

    services.dufs = {
        enable = true;
        user = "qbit";
        group = "qbit";
        servePath = downloadDir;
        port = ports.dufs;
        bindAddresses = [ "127.0.0.1" ];
        settings = {
            allow-upload = true;
            allow-delete = true;
            allow-search = true;
            allow-archive = true;
            hidden = [ ".*" ];
        };
    };

    systemd.services.dufs = {
        after = [ "mkdir-torrent.service" ];
        requires = [ "mkdir-torrent.service" ];
    };

    services.caddy.virtualHosts."im_418".extraConfig =
        let
            inherit (apps.public) torrent_download;
        in
        ''
            @dufs host ${torrent_download.fqdn}
            handle @dufs {
                basic_auth {
                    {env.DOWNLOAD_AUTH_NAME} {env.DOWNLOAD_AUTH_PASSWD}
                }
                reverse_proxy http://localhost:${toString ports.dufs}
            }
        '';

}
