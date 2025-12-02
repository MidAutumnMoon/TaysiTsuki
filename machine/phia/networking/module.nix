{ config, ... }:

{

    networking = with config; {
        hostName = lore.machines.phia.hostname;
        proxy.default = with lore; "http://${apps.homelab.proxy.fqdn}:${toString ports.proxy}";
        useDHCP = false;
    };

    systemd.network.networks = {
        "10-enp2s0" = {
            name = "enp2s0";
            DHCP = "yes";
            networkConfig = {
                MulticastDNS = "resolve";
                DNSSEC = "no";
            };
        };
    };

}
