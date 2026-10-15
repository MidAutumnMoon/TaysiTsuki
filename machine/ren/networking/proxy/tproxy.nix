{ pkgs, config, lib, ... }:

# This module makes devices on the tailnet able to use proxy
# in my homelab.
#
# AI: Learnt policy based routing and nftables tproxy using LLM.

let

    inherit (config) lore;

    iphone = lore.machines.iphone;

    tailscaleIface =
        config.services.tailscale.interfaceName;

    table = "169";

    # before tailscale's 52xx table-52 rules: marked packets resolve
    # via table 169 first, whatever rules tailscale installs. explicit
    # because the kernel used to auto-allocate this priority (observed
    # at both 5209 and 32765 across boots).
    pref = "5200";

    # this module owns mark bits 8-15; tailscale owns 0x00ff0000.
    # the classifier assigns by masked replacement, never by OR, so
    # neither field can contaminate the other. (decimal literals:
    # Nix has no hex ints; nftHex renders them back as hex)
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

    # make ren a exit node
    services.tailscale = {
        useRoutingFeatures = "both";
        extraSetFlags = [
            "--advertise-exit-node"
            # subnet router for the homelab; approval lives in infra
            "--advertise-routes=${lore.network.lan4}"
            # must stay true: accept-dns=false also disables this
            # node's quad-100 forwarder, which exit-node clients rely
            # on (SERVFAIL -> clients fall back to plaintext carrier
            # DNS -> GFW poisoning). host-side: with a global
            # nameserver configured, tailscale0 claims quad-100 with
            # ~. and the host resolves via quad-100 -> sing-box ->
            # dnscrypt; the declared global stub (127.0.0.1) remains
            # the path when tailscaled is down
            "--accept-dns=true"
        ];
    };

    # control-plane traffic goes through sing-box; tailscaled must
    # survive sing-box being down, hence no Requires here
    systemd.services.tailscaled = {
        serviceConfig.Environment = [
            "HTTPS_PROXY=http://127.0.0.1:${toString lore.ports.proxy}"
            "NO_PROXY=localhost,127.0.0.1,::1"
        ];
        after = [ "sing-box.service" ];
        wants = [ "sing-box.service" ];
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
        # a nixos switch reloads the nft tables (new marking) without
        # re-running RemainAfterExit services: marked packets would
        # miss table 169 and leak via the tailscale NAT until this
        # re-installs the matching policy rule. PartOf restarts us
        # with the firewall.
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
            # rules left by the previous implementation: no pref,
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

            # bypass prefixes as data: interval sets keep the rules
            # static however lore's ranges evolve
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
                # between tailscale's mangle chains (-150: its mark
                # bookkeeping is done by then) and the NixOS rpfilter
                # chain (mangle + 10: it consults the mark set here)
                type filter hook prerouting priority mangle + 5; policy accept;

                # only the selected devices, only from the tailnet
                iifname != "${tailscaleIface}" return
                ip saddr @devicesProxy4 jump classify
                ip6 saddr @devicesProxy6 jump classify
            }

            chain classify {
                # kernel bypasses first: local, LAN and tailnet
                # traffic must not depend on sing-box, and local
                # ICMP must survive the protocol drop below
                fib daddr type local counter return comment "bypass-local"
                ip daddr @bypassLan4 counter return comment "bypass-lan"
                ip6 daddr @bypassLan6 counter return comment "bypass-lan"
                ip daddr @bypassTailnet4 counter return comment "bypass-tailnet"
                ip6 daddr @bypassTailnet6 counter return comment "bypass-tailnet"

                # remaining traffic is public: unsupported protocols
                # fail closed (counted), not marked-then-blackholed
                meta l4proto != { tcp, udp } counter drop comment "drop-unsupported"

                # masked assignment and the transparent handoff share
                # one tcp/udp-gated rule: the mark is never set on a
                # packet that is not also given to the socket. nft ends
                # a rule at the newline -- this MUST stay one line
                meta l4proto { tcp, udp } meta mark set (meta mark & ${nftHex keep}) | ${nftHex mark} tproxy to :${toString lore.ports.tproxy} counter accept comment "tproxy"
            }
            '';
    };

    # tproxy preserves the original destination address and port, so
    # transparent packets reach the input chain on arbitrary dports:
    # port-based acceptance can never authorize them (flaw 1 in
    # NETWORKING-PLAN.md). the classifier runs at mangle + 5, before
    # the input chain, so the mark is already set; one inet-family
    # rule covers both families.
    networking.firewall.extraInputRules = ''
        iifname "${tailscaleIface}" meta mark & ${nftHex mask} == ${nftHex mark} counter accept comment "tproxy transparent traffic"
    '';

    # rpfilter sits at mangle + 10, after the classifier, so marked
    # packets resolve through table 169 anyway; explicit accept so
    # this does not depend on that ordering
    networking.firewall.extraReversePathFilterRules = ''
        meta mark & ${nftHex mask} == ${nftHex mark} accept
    '';

}
