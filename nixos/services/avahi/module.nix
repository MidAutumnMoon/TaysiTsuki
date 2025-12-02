{ lib, config, ... }:

let

    tailscaleIface = config.services.tailscale.interfaceName;

in {

    services.avahi =
        lib.mkIf config.services.avahi.enable {
            openFirewall = true;
            nssmdns4 = true;
            nssmdns6 = true;
            publish.enable = true;
            publish.addresses = true;
            publish.userServices = true;
            publish.domain = true;
            denyInterfaces = [ tailscaleIface ];
        };

    systemd.services.avahi-daemon = {
        serviceConfig.ConfigurationDirectory = lib.mkForce [];
    };

}
