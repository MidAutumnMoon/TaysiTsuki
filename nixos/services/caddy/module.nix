{ pkgs, config, lib, ... }:

let

    inherit ( config )
        lore
    ;

    caddyCfg = config.services.caddy;

in

{

    config = lib.mkIf caddyCfg.enable {

        # trusted-only machines set this to false and write
        # their own firewall rules
        services.caddy.openFirewall = lib.mkDefault true;

        services.caddy = {
            logFormat = "output stderr";
            package = pkgs.tsuki.caddy;

            globalConfig = ''
                email acme@418.im

                # h3 deliberately off: multi-address listeners fail
                # the quic handshake and append per-address Alt-Svc.
                # ios caches it, races dead QUIC against working h2,
                # cancels h2 and renders a blank page
                servers {
                    protocols h1 h2
                }
            '';

            # the cloudflare dns plugin resolves via raw cloudflare
            # IPs, so the router firewall must let caddy through.
            # if certs fail to obtain, check for poisoned DNS
            extraConfig = ''
                (tls_cloudflare) {
                    tls {
                        dns cloudflare {env.CLOUDFLARE_API_TOKEN}
                        # le doesn't support it
                        # key_type ed25519
                    }
                }
                (common) {
                    encode zstd gzip
                }
            '';
        };

        services.caddy.virtualHosts."im_418" = {
            listenAddresses = [ "::" ];
            hostName = "*.${lore.domains.im_418}";
            extraConfig = lib.mkMerge [
                (lib.mkBefore ''
                    import common
                    import tls_cloudflare
                '')
                # a final handle so an unmatched hostname gets an
                # explicit 404 instead of the implicit empty 200
                (lib.mkAfter ''
                    handle {
                        respond 404
                    }
                '')
            ];
        };

        sops.templates."cf-token-envfile".content = ''
            CLOUDFLARE_API_TOKEN=${config.sops.placeholder.token--cloudflare}
        '';

        systemd.services.caddy = {
            requires = [ "sops-install-secrets.service" ];
            after = [ "sops-install-secrets.service" ];
            useHardening = true;
            serviceConfig = {
                EnvironmentFile =
                    config.sops.templates."cf-token-envfile".path;
            };
            environment =
                with config.networking.proxy;
                lib.mkIf ( envVars != {} ) envVars;
        };

    };

}
