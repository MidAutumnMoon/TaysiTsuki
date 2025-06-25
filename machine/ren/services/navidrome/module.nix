{ lib, config, pkgs, utils, ... }:

let

    inherit ( config ) lore;

    poolMnt = config.fileSystems."/mnt/pool".mountPoint;

    poolMntUnit =
        "${utils.escapeSystemdPath poolMnt}.mount";

in

{

    services.navidrome = {
        enable = true;
        openFirewall = false;
        settings = {
            # seems reasonable
            EnableInsightsCollector = true;
            Address = "127.0.0.1";
            Port = lore.ports.navidrome;
            MusicFolder = "${poolMnt}/Music";
            # default but without "albumartistid"
            PID.Album = "musicbrainz_albumid|album,albumversion,releasedate";
        };
    };

    systemd.services.navidrome = {
        after = [ poolMntUnit ];
        wants = [ poolMntUnit ];
    };

    services.caddy.virtualHosts."im_418".extraConfig =
        ''
            @music host ${lore.apps.homelab.navidrome.fqdn}
            handle @music {
                reverse_proxy http://127.0.0.1:${toString lore.ports.navidrome}
            }
        '';

}
