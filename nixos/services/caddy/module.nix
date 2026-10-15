{ pkgs, config, lib, ... }:

let

    inherit ( config )
        lore
    ;

    caddyCfg = config.services.caddy;

in

{

    config = lib.mkIf caddyCfg.enable {

        # trusted-only machines override this to false and provide
        # their own networking.firewall rules; upstream opens
        # http(s) ports when this is true
        services.caddy.openFirewall = lib.mkDefault true;

        services.caddy = {
            logFormat = "output stderr";
            package = pkgs.tsuki.caddy;

            globalConfig = ''
                email acme@418.im
                # acme_ca https://acme-staging-v02.api.letsencrypt.org/directory

                # h3 stays off: with explicit multi-address listeners the
                # quic handshake fails and each address appends its own
                # Alt-Svc -- ios caches the advertisement, races dead QUIC
                # against a working h2 connection, cancels the h2 and
                # renders a blank page
                servers {
                    protocols h1 h2
                }
            '';

            # N.B.
            # Caddy will do a DNS lookup using raw Cloudflare IPs,
            # remeber to open firewall on the router for caddy.
            #
            # Also, if it failed to obtain certs, check if DNS is poisoned.
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
