{ lib, config, pkgs, ... }:

let

    poolMnt = config.fileSystems."/mnt/pool".mountPoint;

    inherit ( config )
        lore
    ;

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
            Jukebox.Enabled = true;
            MPVPath = lib.getExe pkgs.mpv;
        };
    };

    services.caddy.virtualHosts."im_418".extraConfig =
        ''
            @music host ${lore.apps.homelab.navidrome.fqdn}
            handle @music {
                reverse_proxy http://127.0.0.1:${toString lore.ports.navidrome}
            }
        '';

}
