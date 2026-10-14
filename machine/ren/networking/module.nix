{ config, ... }:

{

    networking = with config; {
        hostName = lore.machines.umi.hostname;
        proxy.default = "http://localhost:${toString lore.ports.proxy}";
        useDHCP = false;
    };

    systemd.network.networks."10-enp2s0" = {
        name = "enp2s0";
        DHCP = "yes";
        networkConfig.DNSSEC = "no";
    };

    services.resolved.settings.Resolve = {
        DNS = [ "127.0.0.1" ];
        FallbackDNS = [ ];
        Cache = false;
    };

}
