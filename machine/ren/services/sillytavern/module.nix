{ config, pkgs, ... }:

let

    inherit (config) lore;
    tvDomain = lore.apps.homelab.sillytavern.fqdn;
in

{

    services.sillytavern = {
        enable = true;
        listenAddressIPv6 = "::1";
        listenAddressIPv4 = "127.0.0.1";
        port = lore.ports.sillytavern;
    };

    services.sillytavern.configFile =
        pkgs.writers.writeYAML "sillytavern.yml" {
            browserLaunch.enabled = false;
            basicAuthMode = false;
            requestProxy = {
                enabled = true;
                url = config.networking.proxy.allProxy;
            };
            enableUserAccounts = false;
            performance = {
                lazyLoadCharacters = true;
                memoryCacheCapacity = "1gb";
            };
            # cacheBuster.enabled = true;
            whitelistMode = false;
            backups.chat.enabled = false;
            enableDownloadableTokenizers = true;
            thumbnails.enabled = false;
        }
        |> toString;

    services.caddy.virtualHosts."im_418".extraConfig = ''
        @sillytavern {
            host ${tvDomain}
            client_ip private_ranges
        }
        handle @sillytavern {
            reverse_proxy http://127.0.0.1:${toString lore.ports.sillytavern}
        }
    '';
}
