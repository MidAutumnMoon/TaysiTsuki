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
        dns = sharedInfra.ports.dns; # 9098
        dnscryptLocal = 9099;
    };

    lore.domains = sharedInfra.domains;

    lore.apps."homelab" = let
        inherit ( sharedInfra.domains ) im_418;
        inherit ( config.lore ) machines;
        cname = target: subdomain: {
            inherit subdomain;
            domain = im_418.name;
            cname = target;
        };
        onRen = cname machines.ren.mdns;
        onPhia = cname machines.phia.mdns;
    in {
        router = {
            subdomain = "router";
            domain = im_418.name;
            ip = machines.router.static_ip;
        };

        # ren services
        proxy = onRen "proxy";
        clash_dashboard = onRen "clash";
        dns_dashboard = onRen "dnscrypt";
        wpad = onRen "wpad";
        # music = onRen "music" // { tailscale = true; };

        # phia services
        torrent_dashboard = onPhia "qbit";
    };

    # soaRecord imposed by dns.nix
    lore.utils."appToDnsRecords" = appsDef:
        let dnslib = flakes.dns.lib; in
        let try = val: n: fn: if val ? ${n} then fn val.${n} else null; in
        appsDef
        # 1. remove all unset options
        |> lib.mapAttrs ( _: val: lib.rejectUnset val )
        # 2. map our records into dns.nix's format
        # unset record type will be replaced with null
        |> lib.mapAttrs' ( _: val: with dnslib.combinators;
            lib.nameValuePair val.subdomain {
                A = try val "ip" ( v: lib.singleton <| a v  );
                AAAA = try val "ip6" ( v: lib.singleton <| aaaa v  );
                CNAME = try val "cname" ( v: lib.singleton <| cname v  );
            } )
        # 3. remove those nulls introduced last step
        |> lib.mapAttrs ( _: lib.filterAttrs ( _: val: val != null ) )
        # 4. dns.nix skeleton
        |> ( it: {
                SOA = {
                    nameServer = "localhost";
                    adminEmail = "admin@localhost";
                    serial = 20281219;
                };
                subdomains = it;
            } )
    ;

}

# vim: nowrap:
