{ lib, config, ... }:

{

    services.avahi =
        lib.mkIf config.services.avahi.enable {
            openFirewall = true;
            nssmdns4 = true;
            nssmdns6 = true;
            publish.enable = true;
            publish.addresses = true;
            publish.userServices = true;
            publish.domain = true;
        };

}
