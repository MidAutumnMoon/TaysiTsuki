{ pkgs, config, lib, ... }:

# transparent proxying for tailnet devices via this exit node

let

    inherit (config) lore;

    iphone = lore.machines.iphone;

    tailscaleIface =
        config.services.tailscale.interfaceName;

    table = "169";

    # must sort before tailscale's table-52 rules (52xx) so marked
    # packets resolve via table 169 first; explicit because kernel
    # auto-allocation of this priority is unstable across boots
    pref = "5200";

    # this module owns mark bits 8-15; tailscale owns 0x00ff0000.
    # masked replacement, never OR, keeps the fields independent.
    # decimal literals: nix has no hex ints
    mask = 65280; # 0x0000ff00
    mark = 26880; # 0x00006900
    # ~mask: bits preserved while assigning into our field
    keep = builtins.bitXor mask 4294967295;

    nftHex = x: "0x" + lib.toHexString x;

in {

    assertions = [
        {
            assertion = iphone.tailnet_ip != null && iphone.tailnet_ip6 != null;
            message = "tproxy device sets need lore.machines.iphone tailnet addresses";
        }
    ];

    services.tailscale = {
        useRoutingFeatures = "both";
        extraSetFlags = [
            "--advertise-exit-node"
            # route approval lives in infra
            "--advertise-routes=${lore.network.lan4}"
            # must stay true: accept-dns=false also disables this
            # node's quad-100 forwarder that exit-node clients rely
            # on (SERVFAIL would push them onto plaintext carrier
            # dns). host side, quad-100 chains into sing-box ->
            # dnscrypt
            "--accept-dns=true"
        ];
    };

    # the control plane detours via sing-box but must survive it
    # being down: wants, not requires
    systemd.services.tailscaled = {
        serviceConfig.Environment = [
            "HTTPS_PROXY=http://127.0.0.1:${toString lore.ports.proxy}"
            "NO_PROXY=localhost,127.0.0.1,::1"
        ];
        after = [ "sing-box.service" ];
        wants = [ "sing-box.service" ];
    };

    networking.iproute2.enable = true;
    networking.iproute2.rttablesExtraConfig = ''
        ${table} tailscale_proxy
    '';

    # localCommands doesn't work when systemd-networkd
    systemd.services."tproxy-route" = {
        description = "setup routing rules for tproxy";

        wantedBy = [ "multi-user.target" ];
        # a switch reloads nft (new marking) without re-running
        # RemainAfterExit services: the old policy rule would miss
        # the new mark and leak via the tailscale NAT. PartOf
        # restarts us with the firewall
        partOf = [ config.systemd.services."nftables".name ];
        after = [
            "network.target"
            config.systemd.services."nftables".name
        ];
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
            # stale rules from an older revision: no pref,
            # tailscale-overlapping mask
            ip ru d fwmark 0x00690000/0x00ff0000 lookup ${table} || true
            ip -6 ru d fwmark 0x00690000/0x00ff0000 lookup ${table} || true

            ip ru d pref ${pref} fwmark ${nftHex mark}/${nftHex mask} lookup ${table} || true
            ip -6 ru d pref ${pref} fwmark ${nftHex mark}/${nftHex mask} lookup ${table} || true

            ip ru a pref ${pref} fwmark ${nftHex mark}/${nftHex mask} lookup ${table}
            ip -6 ru a pref ${pref} fwmark ${nftHex mark}/${nftHex mask} lookup ${table}

            ip r flush table ${table} || true
            ip r a local default dev lo table ${table}
            ip -6 r flush table ${table} || true
            ip -6 r a local default dev lo table ${table}
        '';
    };

    networking.nftables.enable = true;
    networking.nftables.tables."tailscale-tproxy" = {
        family = "inet";
        content =
            let inherit (lore.network) lan4 lan6 tailnet4 tailnet6; in
            ''
            set devicesProxy4 {
                type ipv4_addr
                elements = { ${iphone.tailnet_ip} }
            }
            set devicesProxy6 {
                type ipv6_addr
                elements = { ${iphone.tailnet_ip6} }
            }

            set bypassLan4 {
                type ipv4_addr
                flags interval
                elements = { ${lan4} }
            }
            set bypassLan6 {
                type ipv6_addr
                flags interval
                elements = { ${lan6} }
            }
            set bypassTailnet4 {
                type ipv4_addr
                flags interval
                elements = { ${tailnet4} }
            }
            set bypassTailnet6 {
                type ipv6_addr
                flags interval
                elements = { ${tailnet6} }
            }

            chain prerouting {
                # after tailscale's mangle chains (-150, their mark
                # bookkeeping done) and before rpfilter (mangle + 10,
                # which consults our mark)
                type filter hook prerouting priority mangle + 5; policy accept;

                iifname != "${tailscaleIface}" return
                ip saddr @devicesProxy4 jump classify
                ip6 saddr @devicesProxy6 jump classify
            }

            chain classify {
                # local, lan and tailnet traffic must not depend on
                # sing-box; the fib return must precede the protocol
                # drop or local ICMP dies with it
                fib daddr type local counter return comment "bypass-local"
                ip daddr @bypassLan4 counter return comment "bypass-lan"
                ip6 daddr @bypassLan6 counter return comment "bypass-lan"
                ip daddr @bypassTailnet4 counter return comment "bypass-tailnet"
                ip6 daddr @bypassTailnet6 counter return comment "bypass-tailnet"

                # unsupported protocols fail closed (counted), not
                # marked-then-blackholed
                meta l4proto != { tcp, udp } counter drop comment "drop-unsupported"

                # mark and tproxy share one rule: nothing is marked
                # without being handed to the socket. nft ends a rule
                # at the newline -- must stay one line
                meta l4proto { tcp, udp } meta mark set (meta mark & ${nftHex keep}) | ${nftHex mark} tproxy to :${toString lore.ports.tproxy} counter accept comment "tproxy"
            }
            '';
    };

    # tproxy preserves daddr/dport, so transparent packets hit the
    # input chain on arbitrary ports; only the mark can authorize
    # them, and the classifier at mangle + 5 has already set it
    networking.firewall.extraInputRules = ''
        iifname "${tailscaleIface}" meta mark & ${nftHex mask} == ${nftHex mark} counter accept comment "tproxy transparent traffic"
    '';

    # rpfilter sits at mangle + 10, after the classifier, so marked
    # packets resolve via table 169 anyway; accept explicitly rather
    # than depend on that ordering
    networking.firewall.extraReversePathFilterRules = ''
        meta mark & ${nftHex mask} == ${nftHex mark} accept
    '';

}
