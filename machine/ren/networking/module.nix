{ lib, config, ... }:

let

    inherit (config.lore)
        machines
        network
    ;

    umi = machines.umi;

in {

    networking = with config; {
        hostName = lore.machines.umi.hostname;
        proxy.default = "http://localhost:${toString lore.ports.proxy}";
        useDHCP = false;

        # trusted-only: ssh admin, caddy serving (see below)
        firewall.extraInputRules =
            let inherit (network) lan4 lan6 tailnet4 tailnet6; in
            ''
                ip saddr { ${lan4}, ${tailnet4} } tcp dport 22 counter accept
                ip6 saddr { ${lan6}, ${tailnet6} } tcp dport 22 counter accept
                ip saddr { ${lan4}, ${tailnet4} } tcp dport { 80, 443 } counter accept
                ip6 saddr { ${lan6}, ${tailnet6} } tcp dport { 80, 443 } counter accept
                ip saddr { ${lan4}, ${tailnet4} } udp dport 443 counter accept
                ip6 saddr { ${lan6}, ${tailnet6} } udp dport 443 counter accept
            '';
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

    #
    # Scoped exposure
    #

    # caddy serves trusted networks only (uk-01 keeps the
    # shared wildcard binding: it is a public VPS)
    services.caddy = {
        openFirewall = false;
        virtualHosts."im_418".listenAddresses = lib.mkForce [
            "127.0.0.1" "::1"
            umi.static_ip umi.static_ip6
        ];
    };

    # umi is administered from trusted networks only; shared
    # behavior (uk-01) is untouched
    services.openssh.openFirewall = false;

}
