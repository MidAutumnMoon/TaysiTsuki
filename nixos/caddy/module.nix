{ pkgs, config, lib, ... }:

let

    inherit ( config )
        lore
    ;

    caddyCfg = config.services.caddy;

    proxyCfg = config.networking.proxy;

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
        hostName = "*.${lore.domains.im_418.name}";
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
        serviceConfig = {
            EnvironmentFile = config.sops.templates."cf-token-envfile".path;
            # Hardening
            RemoveIPC = true;
            NoNewPrivileges = true;
            CapabilityBoundingSet = "";
            ProtectClock = true;
            ProtectKernelLogs = true;
            ProtectControlGroups = true;
            ProtectKernelModules = true;
            ProtectHostname = true;
            ProtectKernelTunables = true;
            ProtectSystem = "strict";
            SystemCallArchitectures = "native";
            MemoryDenyWriteExecute = true;
            RestrictNamespaces = true;
            RestrictSUIDSGID = true;
            RestrictRealtime = true;
            LockPersonality = true;
            SystemCallFilter = "@system-service";
            ProtectProc = "invisible";
            ProcSubset = "pid";
            PrivateMounts = true;
            RestrictAddressFamilies = [
                "AF_UNIX"
                "AF_INET"
                "AF_INET6"
            ];
        };
        environment =
            with proxyCfg;
            lib.mkIf ( envVars != {} ) envVars;
    };

}
