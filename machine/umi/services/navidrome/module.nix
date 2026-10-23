{ config, ... }:

let

    inherit (config) lore;
    
    srvMnt = config.fileSystems."/srv".mountPoint;
    srvPool = "${srvMnt}/Pool";

in {

    services.navidrome = {
        enable = true;
        openFirewall = false;
        settings = {
            # seems reasonable
            EnableInsightsCollector = true;
            Address = "127.0.0.1";
            Port = lore.ports.navidrome;
            MusicFolder = "${srvPool}/Music";
            # default but without "albumartistid"
            PID.Album = "musicbrainz_albumid|album,albumversion,releasedate";
            Plugins.Enabled = false;
        };
    };

    systemd.services.navidrome = {
        unitConfig.WantsMountsFor = [ srvMnt ];
        # For multi-library setup
        serviceConfig.BindReadOnlyPaths = [ srvMnt ];
    };

    services.caddy.virtualHosts."im_418".extraConfig =
        ''
            @music host ${lore.apps.homelab.navidrome.fqdn}
            handle @music {
                reverse_proxy http://127.0.0.1:${toString lore.ports.navidrome}
            }
        '';

}
