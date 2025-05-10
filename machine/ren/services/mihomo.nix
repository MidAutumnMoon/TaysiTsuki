{ config, pkgs, ... }:

let

    listenPort = config.lore.ports.mihomo_listen;
    apiPort = config.lore.ports.mihomo_api;

    restartUnits = [ "mihomo.service" ];

in

{

    # N.B. assume /run/secrets/cert--hysteria_ca exists
    sops.secrets = {
        # The private part, such as ip and passwords.
        "conf--mihomo--private" = {
            sopsFile = ./secrets/conf--mihomo--private.sops.data;
            format = "binary";
            inherit restartUnits;
        };
        "cert--hysteria_ca" = {
            sopsFile = ./secrets/cert--hysteria_ca.sops.yml;
            inherit restartUnits;
        };
    };

    # The full mihomo config. This fragment is not sensitive,
    # put it here to utilize modules system.
    sops.templates."conf--mihomo--full" = {
        content = /* yaml */ ''
            mode: "rule"
            bind-address: "*"
            mixed-port: ${toString listenPort}
            allow-lan: true
            unified-delay: true
            tcp-concurrent: true

            external-controller: "127.0.0.1:${toString apiPort}"
            external-controller-cors:
                allow-origins:
                    - '*'
                allow-private-network: true

            global-client-fingerprint: random
            geodata-loader: standard
            geo-auto-update: true

            ${config.sops.placeholder.conf--mihomo--private}
        '';
        inherit restartUnits;
    };

    services.mihomo = {
        enable = true;
        configFile = config.sops.templates."conf--mihomo--full".path;
        package = pkgs.tsuki.mihomo;
    };

    systemd.services."mihomo" = {
        serviceConfig.LoadCredential = [
            "cert--hysteria_ca:${config.sops.secrets.cert--hysteria_ca.path}"
        ];
        environment = {
            SKIP_SAFE_PATH_CHECK = "1";
        };
        # Without this, mihomo might read the outdated config before sops-nix
        # places the new one in place.
        requires = [ "sops-install-secrets.service" ];
        after = [ "sops-install-secrets.service" ];
    };

    networking.firewall.allowedTCPPorts = [ listenPort ];
    networking.firewall.allowedUDPPorts = [ listenPort ];

    services.caddy.virtualHosts."http://wpad" = let
        wpad = pkgs.writeTextDir "wpad.dat"
            /* javascript */ ''
                function FindProxyForURL( url, host ) {
                    return "PROXY ren.home.lan:${toString listenPort}";
                }
            '';
    in {
        listenAddresses = [ "[::]" ];
        logFormat = ''
            output stderr
        '';
        extraConfig = ''
            root * ${wpad}
            file_server browse
        '';
    };

    services.caddy.virtualHosts."*.home.lan" = {
        extraConfig = ''
            @mihomo host clash.home.lan
            handle @mihomo {
                handle_path /api* {
                    reverse_proxy 127.0.0.1:${toString apiPort}
                }
                root * ${pkgs.tsuki.metacubexd}
                file_server
            }
        '';
    };

    boot.kernel.sysctl = { "net.ipv4.tcp_fastopen" = "3"; };

}
