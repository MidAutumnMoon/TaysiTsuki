{ config, ... }:

{

    networking = with config; {
        hostName = lore.machines.ren.hostname;
        proxy.default = "socks5://localhost:${toString lore.ports.proxy}";
        useDHCP = false;
    };

    systemd.network.networks = {
        "10-enp3s0" = {
            name = "enp3s0";
            DHCP = "yes";
            networkConfig = {
                MulticastDNS = "resolve";
                DNSSEC = "no";
            };
        };
    };

    services.resolved.settings.Resolve = {
        Cache = false;
    };

}
