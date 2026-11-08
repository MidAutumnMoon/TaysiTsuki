{ lib, config, ... }:

let

    tailscaleIface = config.services.tailscale.interfaceName;

in {

    services.avahi =
        lib.mkIf config.services.avahi.enable {
            openFirewall = true;
            nssmdns4 = true;
            nssmdns6 = true;
            settings.publish = {
                "disable-publishing" = false;
                disable-user-service-publishing = false;
                publish-addresses = true;
                publish-domain = true;
            };
            settings.server.deny-interfaces = [ tailscaleIface ];
        };

    systemd.services.avahi-daemon = {
        after = [ "network.target" ];
        wants = [ "network.target" ];
        # Conflict with RO etc overlay
        serviceConfig.ConfigurationDirectory = lib.mkForce [];
    };

}
