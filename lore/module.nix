{ lib, config, flakes, ... }:

let

    sharedInfra = lib.importJSON ./shared.json;

in

{

    imports = [
        ./options.nix
    ];

    assertions = [
        {
            assertion = flakes.self.nixosConfigurations ? "ren";
            message = "`ren` is not here?";
        }
    ];

    lore.tsukiObservatory =
        "${config.users.users.teapot.home}/TaysiTsuki";

    lore.pubkeys = sharedInfra.pubkeys;

    lore.machines = {
        ren = {};
        phia = {};
    };

    lore.ports = {
        proxyPort = 7890;
        torrent = 9094;
        qbitwebui = 9095;
        dnscryptWebui = 9096;
        clashApi = 9097;
        dns = sharedInfra.ports.dns;
    };

    lore.domains = {
        inherit ( sharedInfra.domains )
            im_418
        ;
    };

    lore.apps = {

        # Internal services that only make sense when inside
        # the home network.
        homelab = let
            inherit ( config.lore.domains ) im_418;
            internalCname = from: to: {
                fqdn = "${from}.${im_418.name}";
                cname_target = "${to}.${im_418.internal_zone}.${im_418.name}";
            };
            onRen = name: internalCname name "ren";
            onPhia = name: internalCname name "phia";
        in {
            # others
            router = internalCname "router" "router";

            # ren services
            proxy = onRen "proxy";
            clash_dashboard = onRen "clash";
            dns_dashboard = onRen "dnscrypt";
            wpad = onRen "wpad";

            # phia services
            torrent_dashboard = onPhia "qbit";
        };

        # Services that exposed on the tailnet
        # tailscale = ...

    };

}

# vim: nowrap:
