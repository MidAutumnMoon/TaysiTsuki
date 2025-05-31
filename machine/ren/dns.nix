{ lib, config, pkgs, ... }:

let

    # Listening "[::]:53" will cause port conflictions, and the server
    # doesn't support bind to interface out of the box, plus personal
    # preference which IP addresses shouldn't be hardcoded.
    # To solve it with all these constrains, this wicked workaround was born.
    #
    # N.B.
    # For security reasons, loopback addresses can't be used for dnat by default.
    # Ref: `net.ipv4.conf.interface.route_localnet`
    fakeAddr = "192.168.20.10";
    fkaeAddrV6 = "fd7a:1ca5:11bf::1";

    inherit ( config.lore )
        ports
        domains
        homelab
    ;

    tailscaleCfg = config.services.tailscale;

    forwardingRule =
        pkgs.writeText "dnsfwdrule" ''
            ${domains.internal} 10.0.1.1
            ip6.arpa 10.0.1.1
            in-addr.arpa 10.0.1.1
        '';

    # cloak is cname under the hood, plus free cname flattening
    cloakingRule = pkgs.writeText "dnscnamerule" (
        homelab
        |> lib.attrValues
        |> map ( it: "${it.name} ${it.host}" )
        |> lib.concatStringsSep "\n"
    );

in

{

    networking.firewall = {
        allowedTCPPorts = [ 53 ];
        allowedUDPPorts = [ 53 ];
        trustedInterfaces = [ tailscaleCfg.interfaceName ];
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
            "${fakeAddr}:53"
            "[${fkaeAddrV6}]:53"
            "[::]:${toString ports.dns}"
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

        forwarding_rules = forwardingRule;
        cloaking_rules = cloakingRule;

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
            listen_address = "127.0.0.1:${toString ports.dnscryptWebui}";
            username = "";
            password = "";
            enable_query_log = true;
            privacy_level = 0;
        };
    };

    networking.nftables.tables."dns-nat" = let
        interfaces = [ "enp3s0" ]
            |> lib.concatStringsSep ", "
            |> ( it: "{ ${it} }" );
    in {
        family = "inet";
        content = ''
            chain pre {
                type nat hook prerouting priority dstnat; policy accept
                iifname ${interfaces} \
                    meta l4proto { tcp, udp } th dport 53 \
                    dnat ip to ${fakeAddr}
                iifname ${interfaces} \
                    meta l4proto { tcp, udp } th dport 53 \
                    dnat ip6 to ${fkaeAddrV6}
            }
        '';
    };

    networking.interfaces."lo" = {
        ipv4.addresses = [
            { address = fakeAddr; prefixLength = 32; }
        ];
        ipv6.addresses = [
            { address = fkaeAddrV6; prefixLength = 128; }
        ];
    };

    networking.nameservers = [
        "127.0.0.1:${toString ports.dns}"
    ];

    #
    # caddy config
    #

    services.caddy.virtualHosts."teapot".extraConfig =
        let inherit ( config.services.dnscrypt-proxy2 ) settings; in
        ''
            @dns_dashboard host ${homelab.dns_dashboard.name}
            handle @dns_dashboard {
                reverse_proxy http://${settings.monitoring_ui.listen_address}
            }
        '';

}

# vim: nowrap:
