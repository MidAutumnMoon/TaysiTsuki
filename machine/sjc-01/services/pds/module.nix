{ config, lib, ... }:

{

    services.bluesky-pds = {
        enable = true;
        settings = with config; {
            PDS_PORT = lore.ports.pds;
            PDS_HOSTNAME = lore.apps.public.pds.fqdn;
            PDS_CRAWLERS = lib.concatStringsSep "," [
                "https://bsky.network"
                "https://relay.fire.hose.cam"
                "https://relay.upcloud.world"
            ];

        };
        environmentFiles = [ config.sops.secrets.pds.path ];
    };

    sops.secrets."pds" = {
        sopsFile = ./pds;
        format = "binary";
    };

    systemd.services.bluesky-pds =
        let
            sops = config.systemd.services
                .sops-install-secrets.name;
        in {
            bindsTo = [ sops ];
            after = [ sops ];
            serviceConfig.Environment = with config; [
                # N.B. Reading through pds source code,
                # multiple domains can be set, separated by commas.
                #
                # N.B. Each domain start with ".", may change in future.
                "PDS_SERVICE_HANDLE_DOMAINS=.${lore.apps.public.pds.domain}"
            ];
        };

    # TODO: better handle username
    services.caddy.virtualHosts."im_418".extraConfig =
        let
            settings = config.services.bluesky-pds.settings;
        in lib.mkAfter ''
            handle {
                reverse_proxy http://localhost:${toString settings.PDS_PORT}
            }
        '';
}
