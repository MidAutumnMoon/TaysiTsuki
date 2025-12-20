{ pkgs, config, lib, ... }:

# This module makes devices on the tailnet able to use proxy
# in my homelab.
#
# AI: Learnt policy based routing and nftables tproxy using LLM.

let

    inherit (config) lore;

    tailscaleIface =
        config.services.tailscale.interfaceName;

    table = "169";
    # nice mark
    mask = "0x00ff0000";
    mark = "0x00690000";

in {

    # make ren a exit node
    services.tailscale = {
        useRoutingFeatures = "both";
        extraSetFlags = [ "--advertise-exit-node" ];
    };

    # create custom routing table for PBR later
    networking.iproute2.enable = true;
    networking.iproute2.rttablesExtraConfig = ''
        ${table} tailscale_proxy
    '';

    # localCommands doesn't work when systemd-networkd
    systemd.services."tproxy-route" = {
        description = "setup routing rules for tproxy";

        wantedBy = [ "multi-user.target" ];
        after = [ "network.target" ];
        requires =
            with config.systemd; [
                services."tailscaled".name
                services."sing-box".name
            ];

        path = [ pkgs.iproute2 ];
        serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
        };

        script = ''
            ip ru d fwmark ${mark}/${mask} lookup ${table} || true
            ip -6 ru d fwmark ${mark}/${mask} lookup ${table} || true

            ip ru a fwmark ${mark}/${mask} lookup ${table} || true
            ip -6 ru a fwmark ${mark}/${mask} lookup ${table} || true

            ip r flush table ${table} || true
            ip r a local default dev lo table ${table}
            ip -6 r flush table ${table} || true
            ip -6 r a local default dev lo table ${table}
        '';
    };

    networking.nftables.enable = true;
    networking.nftables.tables."tailscale-tproxy" = {
        family = "inet";
        content = ''
            set devicesProxy4 {
                type ipv4_addr
                elements = { 100.117.156.47 }
            }
            set devicesProxy6 {
                type ipv6_addr
                elements = { fd7a:115c:a1e0::4901:9c2f }
            }

            chain prerouting {
                type filter hook prerouting priority mangle; policy accept
                iifname != "${tailscaleIface}" return
                # ip saddr @devicesProxy4 meta nftrace set 1
                ip saddr @devicesProxy4 jump handle_tproxy
                ip6 saddr @devicesProxy6 jump handle_tproxy
            }

            chain handle_tproxy {
                meta mark set meta mark | ${mark}
                meta l4proto { tcp, udp } tproxy \
                    to :${toString lore.ports.tproxy} counter accept
            }
        '';
    };

    networking.firewall.extraReversePathFilterRules = ''
        meta mark & ${mask} == ${mark} accept
    '';

}
