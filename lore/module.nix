{ lib, config, flakes, ... }:

let

    sharedInfra = lib.importJSON ./shared.json;

in

{

    imports = [
        ./options.nix
    ];

    lore.tsukiObservatory =
        "${config.users.users.teapot.home}/TaysiTsuki";

    lore.pubkeys = sharedInfra.pubkeys;

    lore.machines = {
        ren = {};
        phia = {};

        # router is in fact openwrt
        # put it here so that it can be referred elsewhere
        router = {
            static_ip = "10.0.1.1";
        };
    };

    lore.ports = {
        proxyPort = 7890;
        torrent = 9094;
        qbitwebui = 9095;
        dnscryptWebui = 9096;
        clashApi = 9097;
        dns = sharedInfra.ports.dns;
    };

    # Internal services that only make sense when inside
    # the home network.
    lore.apps."homelab" = let
        inherit ( sharedInfra.domains ) im_418;
        inherit ( config.lore ) machines;
        cname = target: from: {
            fqdn = "${from}.${im_418.name}";
            cname = target;
        };
        onRen = cname machines.ren.mdns;
        onPhia = cname machines.phia.mdns;
    in {
        router = {
            fqdn = "router.${im_418.name}";
            ip = machines.router.static_ip;
        };

        # ren services
        proxy = onRen "proxy";
        clash_dashboard = onRen "clash";
        dns_dashboard = onRen "dnscrypt";
        wpad = onRen "wpad";

        # phia services
        torrent_dashboard = onPhia "qbit";
    };

}

# vim: nowrap:
