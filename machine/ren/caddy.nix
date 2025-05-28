{ lib, config, ... }:

{

    networking.firewall.allowedTCPPorts = [ 80 443 ];

    networking.firewall.allowedUDPPorts = [ 443 ];

    systemd.services."caddy" = {
        serviceConfig.LoadCredential = with config.sops.secrets; [
            "cert--home_lan--cert:${cert--home_lan--cert.path}"
            "cert--home_lan--key:${cert--home_lan--key.path}"
        ];
    };

    services.caddy.enable = true;

    services.caddy.virtualHosts."*.home.lan" = {
        listenAddresses = [ "[::]" ];
        logFormat = ''
            output stderr
        '';
        extraConfig = lib.mkBefore ''
            tls \
                {env.CREDENTIALS_DIRECTORY}/cert--home_lan--cert \
                {env.CREDENTIALS_DIRECTORY}/cert--home_lan--key
            encode zstd gzip
        '';
    };

}
