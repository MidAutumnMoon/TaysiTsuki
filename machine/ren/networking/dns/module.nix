{ lib, config, pkgs, flakes, ... }:

let

    # N.B.
    # For security reasons, loopback addresses can't be used for dnat by default.
    # Ref: `net.ipv4.conf.interface.route_localnet`
    fakeAddr = "192.168.20.10";
    fakeAddrV6 = "fd7a:1ca5:11bf::1";

    inherit ( config )
        lore
    ;

    inherit ( lore )
        ports
        apps
    ;

in

{

    networking.firewall = {
        allowedTCPPorts = [ 53 ];
        allowedUDPPorts = [ 53 ];
    };

    services.avahi2dns.enable = true;

    # coredns provides homelab domain resolution
    services.coredns = {
        enable = true;
        package = pkgs.tsuki.coredns;
        config =
            let
                hostSystem = pkgs.stdenv.hostPlatform.system;
                inherit (flakes.dns.util.${hostSystem}) writeZone;
                appToZone = app:
                    lore.utils.appToDnsRecords app |> writeZone "418.im";
            in ''
                .:53 {
                    bind ${fakeAddr} ${fakeAddrV6}
                    log
                    # N.B. multiple directives cause later one
                    # to override previous ones
                    file ${appToZone <| apps.homelab // apps.tailnet} {
                        # at least v1.12.2
                        fallthrough
                    }
                    forward local /etc/resolv.conf
                    forward . [::1]:${toString ports.dnscryptLocal}
                    cache 60 {
                        disable success local
                        disable denial local
                    }
                }
            '';
    };

    # dnscrypt-proxy resolves internet names
    services.dnscrypt-proxy = {
        enable = true;
        upstreamDefaults = false;
        settings = rec {
            # Global Options
            server_names = lib.attrNames static;
            listen_addresses = [ "[::]:${toString ports.dnscryptLocal}" ];
            bootstrap_resolvers = [ "223.5.5.5:53" ];
            netprobe_address = "8.8.8.8:53";
            # cache handled by coredns
            cache = false;
            ignore_system_dns = true;
            # Static Servers
            static."doh-pub".stamp = "sdns://AgcAAAAAAAAAAAAHZG9oLnB1YgovZG5zLXF1ZXJ5";
            static."alidns".stamp = "sdns://AgcAAAAAAAAAAAAOZG5zLmFsaWRucy5jb20KL2Rucy1xdWVyeQ";
            # Blocklist
            blocked_names = {
                blocked_names_file = pkgs.tsuki.adblocklist;
                log_file = "/dev/stdout";
            };
            # Logging
            query_log.file = "/dev/stdout";
            nx_log.file = "/dev/stdout";
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
    };

    networking.nftables.tables."dns-nat" =
        let
            interfaces = [ "enp3s0" ]
                |> lib.concatStringsSep ", "
                |> ( it: "{ ${it} }" );
        in {
            family = "inet";
            content = ''
                chain pre {
                    type nat hook prerouting priority dstnat; policy accept
                    iifname ${interfaces} meta l4proto { tcp, udp } th dport 53 \
                        dnat ip to ${fakeAddr}
                    iifname ${interfaces} meta l4proto { tcp, udp } th dport 53 \
                        dnat ip6 to ${fakeAddrV6}
                }
            '';
        };

    networking = {
        interfaces."lo" = {
            ipv4.addresses = [
                { address = fakeAddr; prefixLength = 32; }
            ];
            ipv6.addresses = [
                { address = fakeAddrV6; prefixLength = 128; }
            ];
        };
        nameservers = [ fakeAddr fakeAddrV6 ];
    };

    #
    # caddy config
    #

    services.caddy.virtualHosts."im_418".extraConfig =
        let inherit ( config.services.dnscrypt-proxy ) settings; in
        ''
            @dns_dashboard host ${apps.homelab.dns_dashboard.fqdn}
            handle @dns_dashboard {
                reverse_proxy http://${settings.monitoring_ui.listen_address}
            }
        '';

}

# vim: nowrap:
