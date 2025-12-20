{ lib, config, ... }:

{

    imports = [
        ./options.nix
    ];

    lore.tsukiObservatory =
        "${config.users.users.teapot.home}/TaysiTsuki";

    lore.pubkeys = lib.importJSON ./pubkeys.json;

    lore.machines = {
        ren = {};
        phia = {};

        # router is in fact openwrt
        # put it here so that it can be referred elsewhere
        router = {
            static_ip = "10.0.1.1";
        };

        uk-01 = {};
        sjc-01 = {};
    };

    lore.ports = {
        proxy = 7890;
        tproxy = 7891;
        torrent = 9094;
        qbitwebui = 9095;
        clashApi = 9097;
        dns = 9098;
        dnscryptLocal = 9099;
        navidrome = 9100;
        peerbanhelper = 9101;
        avahi2dns = 9102;
        pds = 9103;
        tangledKnot = 9104;
        tangledKnotInternal = 9105;
        slskd = 9106;
        slskdWebui = 9107;
        sillytavern = 9108;
    };

    lore.domains = rec {
        "im_418" = "418.im";
        "im_418_ts" = "tailscale.${im_418}";
    };

    lore.apps."homelab" =
        let
            inherit (config.lore) machines;
            inherit (config.lore.domains) im_418;
            cname = target: subdomain: {
                inherit subdomain;
                domain = im_418;
                cname = target;
            };
            onRen = cname machines.ren.mdns;
            onPhia = cname machines.phia.mdns;
        in {
            router = {
                subdomain = "router";
                domain = im_418;
                ip = machines.router.static_ip;
            };

            # ren services
            proxy = onRen "proxy";
            wpad = onRen "wpad";
            navidrome = onRen "music";
            peerban = onRen "peerban";
            sillytavern = onRen "tv";

            # phia services
            torrent_dashboard = onPhia "qbit";
        };

    lore.apps."tailnet" =
        let
            inherit (config.lore.domains) im_418;
            on = node: subdomain: {
                inherit subdomain;
                domain = im_418;
                cname = "${node}.tailscale.${im_418}";
            };
        in {
            downloader_dashboard = on "uk-01" "2qbit";
            slskd_dashboard = on "uk-01" "slskd";
            clash_dashboard = on "ren" "clash";
        };

    lore.apps."public" =
        let inherit (config.lore.domains) im_418; in
        {
            torrent_download = {
                subdomain = "td";
                domain = im_418;
            };
            pds = {
                subdomain = "pds";
                domain = im_418;
            };
            tangled_knot = {
                subdomain = "knot";
                domain = im_418;
            };
        };

}
