{ lib, config, pkgs, ... }:

let

    # The default "0.0.0.0" causes confliction, and dnscrypt-proxy
    # doesn't support listening on interface, and I don't want
    # to hardcode ip addresses in config. This is the ultimate workaround :/
    #
    # In following config, this address is assigned to "lo", so that
    # it can listen on it, and NAT is used to forward traffic.
    #
    # N.B., the loopback "127.0.0.0/8" can't be used for NAT by default
    # for security reasones. Setting net.ipv4.conf.<if>.route_localnet=1
    # can disable this security feature.
    bindAddr = "192.168.20.10";
    bindAddrv6 = "fd7a:1ca5:11bf::1";

    inherit ( config.lore.ports )
        dnscryptWebui
    ;

    inherit ( config.lore )
        domains
    ;

    forwardingRule =
        pkgs.writeText "dnsfwdrule" ''
            home.lan 10.0.1.1
            ${domains.internal} 10.0.1.1
        '';

in

{

    passthru = { inherit forwardingRule; };

    networking.firewall = {
        allowedTCPPorts = [ 53 ];
        allowedUDPPorts = [ 53 ];
    };

    services.dnscrypt-proxy2 = {
        enable = true;
        upstreamDefaults = false;
    };

    services.dnscrypt-proxy2.settings = let
        stdout = "/dev/stdout";
    in rec {
        # Global Options
        server_names = lib.attrNames static;
        listen_addresses = [
            "${bindAddr}:53"
            "[${bindAddrv6}]:53"
        ];

        bootstrap_resolvers = [
            "223.5.5.5:53"
            "119.29.29.29:53"
            "[2402:4e00::]:53"
        ];

        netprobe_address = "8.8.8.8:53";

        cache = true;
        block_undelegated = true;
        block_unqualified = true;
        block_ipv6 = false;
        lb_estimator = true;
        use_syslog = true;
        ignore_system_dns = true;

        # Forwarding Rule
        forwarding_rules = forwardingRule;

        # Static Servers
        static."doh-pub".stamp = "sdns://AgcAAAAAAAAAAAAHZG9oLnB1YgovZG5zLXF1ZXJ5";
        static."alidns".stamp = "sdns://AgcAAAAAAAAAAAAOZG5zLmFsaWRucy5jb20KL2Rucy1xdWVyeQ";

        # Blocklist
        blocked_names = {
            blocked_names_file = pkgs.tsuki.adblocklist;
            log_file = stdout;
        };

        # Logging

        query_log.file = stdout;
        nx_log.file = stdout;

        # Monitoring UI
        monitoring_ui = {
            enabled = true;
            listen_address = "127.0.0.1:${toString dnscryptWebui}";
            username = "";
            password = "";
            enable_query_log = true;
            privacy_level = 0;
        };
    };

    networking.nftables.tables."dns-nat" = let
        interfaces = [ "enp3s0" config.services.tailscale.interfaceName ]
            |> lib.concatStringsSep ", "
            |> ( it: "{ ${it} }" );
    in {
        family = "inet";
        content = ''
            chain pre {
                type nat hook prerouting priority dstnat; policy accept
                iifname ${interfaces} \
                    meta l4proto { tcp, udp } th dport 53 \
                    dnat ip to ${bindAddr}
                iifname ${interfaces} \
                    meta l4proto { tcp, udp } th dport 53 \
                    dnat ip6 to ${bindAddrv6}
            }
        '';
    };

    networking.interfaces."lo" = {
        ipv4.addresses = [
            { address = bindAddr; prefixLength = 32; }
        ];
        ipv6.addresses = [
            { address = bindAddrv6; prefixLength = 128; }
        ];
    };

    networking.nameservers = [ bindAddr ];


    #
    # caddy config
    #

    services.caddy.virtualHosts."*.home.lan".extraConfig = let
        inherit ( config.services.dnscrypt-proxy2 )
            settings;
    in ''
        @dnsmonitor host dns.home.lan
        handle @dnsmonitor {
            reverse_proxy http://${settings.monitoring_ui.listen_address}
        }
    '';

}

# vim: nowrap:
