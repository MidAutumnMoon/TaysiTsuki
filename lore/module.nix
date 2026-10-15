{ lib, config, ... }:

{

    imports = [
        ./options.nix
    ];

    lore.tsukiObservatory =
        "${config.users.users.teapot.home}/TaysiTsuki";

    lore.pubkeys = lib.importJSON ./pubkeys.json;

    lore.machines = {
        umi = {
            static_ip = "10.0.1.30";
            static_ip6 = "fda1:ac04:d4f6:0:4af3:17ff:fe19:6f16";
            tailnet_ip = "100.113.193.81";
            tailnet_ip6 = "fd7a:115c:a1e0::cb3b:c152";
        };
        phia = {};

        iphone = {
            tailnet_ip = "100.117.156.47";
            tailnet_ip6 = "fd7a:115c:a1e0::4901:9c2f";
        };

        # router is in fact openwrt
        # put it here so that it can be referred elsewhere
        router = {
            static_ip = "10.0.1.1";
        };

        uk-01 = {
            tailnet_ip = "100.111.77.92";
            tailnet_ip6 = "fd7a:115c:a1e0::c201:4d60";
        };
    };

    lore.ports = {
        proxy = 7890;
        tproxy = 7891;
        torrent = 9094;
        qbitwebui = 9095;
        clashApi = 9097;
        navidrome = 9100;
        peerbanhelper = 9101;
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

    lore.network = {
        lan4 = "10.0.1.0/24";
        lan6 = "fda1:ac04:d4f6:0::/64";
        tailnet4 = "100.64.0.0/10";
        tailnet6 = "fd7a:115c:a1e0::/48";
    };

    lore.apps."homelab" =
        let
            inherit (config.lore) machines;
            inherit (config.lore.domains) im_418;
            cname = target: subdomain: {
                inherit subdomain;
                domain = im_418;
                cname = target;
                ip = null;
                ip6 = null;
            };
            onRen = cname "${machines.umi.hostname}.${im_418}";
        in {
            router = {
                subdomain = "router";
                domain = im_418;
                cname = null;
                ip = machines.router.static_ip;
                ip6 = null;
            };

            # ren services
            proxy = onRen "proxy";
            wpad = onRen "wpad";
            navidrome = onRen "music";
            peerban = onRen "peerban";
            sillytavern = onRen "tv";
            clash_dashboard = onRen "clash";
        };

    lore.apps."tailnet" =
        let
            inherit (config.lore.machines) uk-01;
            inherit (config.lore.domains) im_418;
        in {
            slskd_dashboard = {
                subdomain = "slskd";
                domain = im_418;
                cname = null;
                ip = uk-01.tailnet_ip;
                ip6 = uk-01.tailnet_ip6;
            };
        };

    lore.apps."public" =
        let inherit (config.lore.domains) im_418; in
        {
            torrent_download = {
                subdomain = "td";
                domain = im_418;
            };
            downloader_dashboard = {
                subdomain = "2qbit";
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

    assertions =
        let
            inherit (config.lore) apps machines domains;
            umiFqdn = "${machines.umi.hostname}.${domains.im_418}";
            # a homelab app either aliases umi (cname alone) or
            # carries an ip (ip6 optional alongside it)
            homelabBad = apps.homelab
                |> lib.attrValues
                |> lib.filter (app:
                    ( app.cname != null
                        && ( app.cname != umiFqdn
                            || app.ip != null
                            || app.ip6 != null ) )
                    || ( app.cname == null && app.ip == null ))
                |> lib.map (app: app.fqdn);
            tailnetWithoutAddrs = apps.tailnet
                |> lib.attrValues
                |> lib.filter (app: app.ip == null || app.ip6 == null)
                |> lib.map (app: app.fqdn);
        in [
            {
                assertion = homelabBad == [];
                message = "homelab apps must alias umi (${umiFqdn}) via cname alone, "
                    + "or carry an ip (ip6 optional): "
                    + builtins.toJSON homelabBad;
            }
            {
                assertion = tailnetWithoutAddrs == [];
                message = "tailnet apps need both ip and ip6: "
                    + builtins.toJSON tailnetWithoutAddrs;
            }
        ];

}
