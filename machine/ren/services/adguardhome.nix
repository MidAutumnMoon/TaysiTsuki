{ lib, config, ... }:

let

    # The default "0.0.0.0" causes confliction, and adguard home
    # doesn't support listening on interface, and I don't want
    # to hardcode ip addresses in config. This is the ultimate workaround :/
    #
    # In following config, this address is assigned to "lo", so that
    # adguard can listen on it, and NAT is used to forward traffic
    # from the public interface to adguard.
    #
    # Note, the loopback "127.0.0.0/8" can't be used for NAT by default
    # for security reasones. Setting net.ipv4.conf.<if>.route_localnet=1
    # can disable this security feature.
    bindAddr = "192.168.20.10";

in

{

    networking.firewall.allowedTCPPorts = [ 53 ];
    networking.firewall.allowedUDPPorts = [ 53 ];

    services.adguardhome = {
        enable = true;
        host = "127.0.0.1";
        port = config.lore.ports.adguardhome_webui;
        settings = {
            filters = [
                {
                    enabled = true;
                    url = "https://ruleset.skk.moe/Internal/reject-adguardhome.txt";
                    name = "SKK ruleset";
                    id = 101;
                }
                {
                    enabled = true;
                    url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_1.txt";
                    name = "AdGuard DNS Filter";
                    id = 102;
                }
            ];
            dns.bind_hosts = [ bindAddr ];
            dns.port = 53;
            dns.upstream_dns = [
                "[/home.lan/]udp://10.0.1.1:53"
                "https://dns.alidns.com/dns-query"
                "https://doh.pub/dns-query"
                "tls://dot.pub"
            ];
            dns.bootstrap_dns = [
                "223.5.5.5"
                "119.29.29.29"
                "2402:4e00::"
            ];
            dns.cache_optimistic = true;
            querylog.ignored = [ ".arpa" ];
            statistics.ignored = [ ".arpa" ];
        };
    };

    networking.nftables.tables."adguard-nat" = {
        family = "ip";
        content = ''
            chain pre {
                type nat hook prerouting priority dstnat; policy accept
                iifname "enp3s0" \
                    meta l4proto { tcp, udp } th dport 53 \
                    dnat to ${bindAddr}
            }
        '';
    };

    networking.interfaces."lo".ipv4.addresses = [
        { address = bindAddr; prefixLength = 32; }
    ];

    networking.nameservers = [ bindAddr ];


    #
    # caddy config
    #

    services.caddy.virtualHosts."*.home.lan".extraConfig = let
        inherit ( config.services.adguardhome )
            port host
        ;
    in ''
        @adguardhome host dns.home.lan
        handle @adguardhome {
            reverse_proxy http://${host}:${toString port}
        }
    '';

}

# vim: nowrap:
