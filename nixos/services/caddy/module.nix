{ pkgs, config, lib, ... }:

let

    inherit ( config )
        lore
    ;

    caddyCfg = config.services.caddy;

in

lib.mkIf caddyCfg.enable {

    networking.firewall = {
        allowedTCPPorts = [ 80 443 ];
        allowedUDPPorts = [ 443 ];
    };

    services.caddy = {
        logFormat = "output stderr";
        package = pkgs.tsuki.caddy;

        globalConfig = ''
            email acme@418.im
            # acme_ca https://acme-staging-v02.api.letsencrypt.org/directory
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
        extraConfig = lib.mkBefore ''
            import common
            import tls_cloudflare
        '';
    };

    sops.templates."cf-token-envfile".content = ''
        CLOUDFLARE_API_TOKEN=${config.sops.placeholder.token--cloudflare}
    '';

    systemd.services.caddy = {
        requires = [ "sops-install-secrets.service" ];
        after = [ "sops-install-secrets.service" ];
        useHardening = true;
        serviceConfig = {
            EnvironmentFile = config.sops.templates."cf-token-envfile".path;
        };
        environment =
            with config.networking.proxy;
            lib.mkIf ( envVars != {} ) envVars;
    };

}
