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
                requestCompression.enabled = true;
            };
            # cacheBuster.enabled = true;
            whitelistMode = false;
            backups = {
                common.numberOfBackups = 0;
                chat.enabled = false;
            };
            enableDownloadableTokenizers = true;
            # set to false if theme requires HQ pics
            thumbnails.enabled = true;
            enableKeepAlive = true;
            whitelistImportDomains = [
                "localhost"
                "cdn.discordapp.com"
                "files.catbox.moe"
                "raw.githubusercontent.com"
                "botbooru.com"
            ];
            enableServerPlugins = true;
            enableServerPluginsAutoUpdate = false;
        }
        |> toString;

    systemd.services."sillytavern" = {
        environment = {
            NODE_ENV = "production";
        }
        // config.networking.proxy.envVars
        ;
    };

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
