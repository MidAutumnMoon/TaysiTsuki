{ flakes, config, ... }:

{

    imports = [ flakes.tangled.nixosModules.knot ];

    services.tangled.knot = {
        enable = true;
        server = with config; {
            listenAddr = "localhost:${toString lore.ports.tangledKnot}";
            internalListenAddr =
                "localhost:${toString lore.ports.tangledKnotInternal}";
            owner = "did:plc:a4xfuo6ypcagbiiqocyhgklv";
            hostname = lore.apps.public.tangled_knot.fqdn;
        };
        git = {
            userName = "tangled0nTeapot";
            userEmail = "noreply@418.m";
        };
    };

    services.caddy.virtualHosts."im_418".extraConfig =
        let
            knotCfg = config.services.tangled.knot.server;
        in ''
            @knot host ${knotCfg.hostname}
            handle @knot {
                reverse_proxy http://${knotCfg.listenAddr}
            }
        '';

}
