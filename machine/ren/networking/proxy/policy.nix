{
    # :: path
    # :: path
    loreFile,
    secretsFile,
}:

# Plaintext sing-box policy: inbounds, dns, routing, selectors and
# logging live here; the encrypted secrets file carries only the
# commercial outbounds whole (server, port, credentials, sni) plus
# the clash api secret. Node tags are duplicated between the two on
# purpose -- they surface in logs and the clash api anyway -- and
# every selector member is a lookup into the secrets outbounds
# (nodeTags below), so tag drift between the files fails evaluation
# before any process is touched. `sing-box check` in the unit
# validates schema only; it does not catch dangling references.

let

    inherit (builtins)
        attrValues
        listToAttrs
    ;

    lore = import loreFile;
    secrets = import secretsFile;

    # :: string -> ( string -> path ) -> string -> rule_set object
    mkRuleset = prefix: dataOf: name: {
        tag = "${prefix} ${name}";
        type = "local";
        format = "binary";
        path = dataOf name;
    };

    # :: string -> ( string -> path ) -> [ string ] -> [ rule_set object ]
    mkRulesets = prefix: dataOf: names:
        map (mkRuleset prefix dataOf) names;

    # :: { tag :: string } -> string
    getTags = map (o: o.tag);

    flatten = val: with builtins;
        if isList val
        then concatMap (v: flatten v) val
        else [ val ];

    # commercial nodes from the encrypted file, addressed by tag
    __nodes = secrets.outbounds;
    nodeByName = listToAttrs <| map (o: { name = o.tag; value = o; }) __nodes;

    # :: [ string ] -> [ tag ]
    # selector members as lookups into nodeByName: a selector naming
    # a node the secrets file does not carry fails evaluation here
    nodeTags = names: map (name: nodeByName.${name}.tag) names;

in rec {

    #
    # Some global settings
    #

    log = {
        level = "info";
        timestamp = false;
    };

    experimental = {
        cache_file.enabled = true;
        clash_api = {
            external_controller = lore.clashApiAddr;
            secret = secrets.clash_api_secret;
        };
    };

    #
    # DNS
    #

    __dnsServers = {
        # dnscrypt on the loopback. the host stub itself detours via
        # quad-100, so type "local" would resolve through the stub ->
        # quad-100 -> this dns engine: a cycle.
        local = {
            tag = "DNS Local";
            type = "udp";
            server = "127.0.0.1";
            server_port = 53;
        };
        cloudflare = {
            tag = "DNS Cloudflare";
            type = "https";
            server = "cloudflare-dns.com";
            # bootstrap via dnscrypt (the local server above), never
            # via quad-100: same cycle as the note on local.
            domain_resolver.server = __dnsServers.local.tag;
            detour = __groups.proxy.tag;
        };
    };

    dns.servers = attrValues __dnsServers;

    dns.rules = [
        {
            domain_suffix = lore.noproxyDomains ++ lore.tailnetDomains;
            rule_set = getTags <| __geositeRuleset.china;
            disable_cache = true;
            server = __dnsServers.local.tag;
        }
    ];

    dns.final = __dnsServers.cloudflare.tag;

    #
    # Inbounds
    #

    __inbounds = {
        # trusted devices only: loopback + the lan address. the
        # firewall decides who is trusted; no wildcard bind.
        main = {
            type = "mixed";
            tag = "Inbound Main";
            listen = "127.0.0.1";
            listen_port = lore.listenPort;
            reuse_addr = true;
        };
        main_lan = {
            type = "mixed";
            tag = "Inbound Main Lan";
            listen = lore.lanIp;
            listen_port = lore.listenPort;
            reuse_addr = true;
        };
        tproxy_tcp = {
            type = "tproxy";
            tag = "Inbound Tproxy Tcp";
            network = "tcp";
            listen = "::";
            listen_port = lore.tproxyPort;
        };
        tproxy_udp = {
            type = "tproxy";
            tag = "Inbound Tproxy Udp";
            network = "udp";
            listen = "::";
            listen_port = lore.tproxyPort;
        };
        # dns entry point for tailnet clients (dns capture, see
        # infra/tailscale.tf): port 53 from any inbound is hijacked
        # into the dns engine by the route rules below.
        tailnet_dns = {
            type = "direct";
            tag = "Inbound Tailnet Dns";
            listen = lore.tailnetIp;
            listen_port = 53;
        };
    };

    inbounds = attrValues __inbounds;

    #
    # Outbounds & Nodes
    #

    __outs = {
        direct = {
            type = "direct";
            tag = "Outbound Direct";
            domain_resolver = {
                server = __dnsServers.local.tag;
                disable_cache = true;
            };
        };
        tailscale = {
            type = "direct";
            tag = "Outbound Tailscale Interface";
            domain_resolver = {
                server = __dnsServers.local.tag;
                disable_cache = true;
            };
            bind_interface = "tailscale0";
        };
    } // nodeByName;

    __groups = {
        proxy = {
            type = "selector";
            tag = "Proxy";
            outbounds = with __groups; getTags [
                proxy_japan
                proxy_europe
                proxy_us
                proxy_all_outbounds
                proxy_hz_upload
            ];
        };

        proxy_japan = {
            type = "selector";
            tag = "Proxy JP";
            outbounds = nodeTags [
                "Backwave JP"
                "Backwave JP Naive"
                "Backwave JP IPv4"
                "Backwave JP Naive IPv4"
            ];
        };

        proxy_europe = {
            type = "selector";
            tag = "Proxy EU";
            outbounds = nodeTags [
                "Nube DE Opt"
                "Nube DE Opt IPv4"
                "Nube DE Opt IPv4 Hy2"
            ];
        };

        proxy_us = {
            type = "selector";
            tag = "Proxy US";
            # the first member is the selector default and must be
            # dual-stack: an ipv6-only default cannot dial ipv4
            # destinations at all
            outbounds = nodeTags [
                "Backwave US Lax"
                "Backwave US Lax Hy2"
                "Backwave US Lax IPv4 Hy2"
                "Backwave US IPv6 Only"
                "Backwave US IPv6 Only Hy2"
            ];
        };

        proxy_hz_upload = {
            type = "selector";
            tag = "Proxy Storage Box Upload";
            outbounds = nodeTags [
                "Backwave US Lax"
                "Backwave US Lax Hy2"
                "Backwave JP"
                "Backwave JP Naive"
                "Backwave JP IPv4"
                "Backwave JP Naive IPv4"
            ];
        };

        # commercial nodes only: direct / tailscale are routing
        # destinations, not proxy choices
        proxy_all_outbounds = {
            type = "selector";
            tag = "Proxy All Outbounds";
            outbounds = getTags __nodes;
        };
    };

    outbounds = attrValues <| __outs // __groups;

    #
    # Route rules
    #

    __3pRuleset = {
        skk = {
            tag = "Ruleset SKK Blocklist";
            type = "remote";
            url = "https://ruleset.skk.moe/sing-box/domainset/reject.json";
        };
        antiAD = {
            tag = "Ruleset anti-AD Blocklist";
            type = "remote";
            url = "https://raw.githubusercontent.com/privacy-protection-tools/anti-ad.github.io/master/docs/anti-ad-sing-box.srs";
        };
    };

    __geositeRuleset = {
        china = mkRulesets "Geosite" lore.geositeDataOf [
            "alibaba"
            "baidu"
            "bilibili"
            "jd"
            "smzdm"
            "steam@cn"
            "tencent"
            "qiniu"
            "zhihu"
            "volcengine"
            "lark"
            "qcloud"
            "ucloud"
            "category-netdisk-cn"
            "category-cdn-cn"
            "huaweicloud"
        ];
        japan = mkRulesets "Geosite" lore.geositeDataOf [
            "dlsite"
            "pixiv"
            "dmm"
        ];
        europe = mkRulesets "Geosite" lore.geositeDataOf [
            "hetzner"
        ];
        manual_select = mkRulesets "Geosite" lore.geositeDataOf [
            "ehentai"
        ];
    };

    __geoipRuleset = {
        cn = mkRuleset "Geoip" lore.geoipDataOf "cn";
    };

    route = {
        final = __groups.proxy.tag;
        auto_detect_interface = true;
        default_domain_resolver = __dnsServers.cloudflare.tag;
    };

    route.rule_set =
        flatten ( attrValues <| __3pRuleset // __geositeRuleset )
        ++ attrValues __geoipRuleset;

    route.rules = [
        {
            action = "sniff";
            timeout = "1s";
        }

        # dns from any inbound -- the tailnet listener above and
        # tproxy alike -- enters the dns engine
        {
            port = 53;
            action = "hijack-dns";
        }


        # Block
        {
            rule_set = [
                __3pRuleset.skk.tag
                __3pRuleset.antiAD.tag
            ];
            domain_suffix = [
                "jddebug.com"
            ];
            action = "reject";
        }

        # Direct
        {
            ip_cidr = [
                "fd7a:115c:a1e0::/48"
                "100.64.0.0/10"
            ];
            outbound = __outs.tailscale.tag;
        }
        {
            ip_is_private = true;
            outbound = __outs.direct.tag;
        }
        {
            domain_suffix = lore.noproxyDomains;
            outbound = __outs.direct.tag;
        }
        {
            domain_suffix = lore.tailnetDomains;
            outbound = __outs.tailscale.tag;
        }

        # Manual select
        {
            rule_set = getTags <| __geositeRuleset.manual_select;
            outbound = __groups.proxy_all_outbounds.tag;
        }
        {
            domain_suffix = [
                "your-storagebox.de"
            ];
            outbound = __groups.proxy_hz_upload.tag;
        }

        # China
        {
            rule_set = getTags <| __geositeRuleset.china;
            domain_suffix = [
                ".cn"
                "xiachufang.com"
                "chiphell.com"
                "modelscope.net"
            ];
            outbound = __outs.direct.tag;
        }

        # Japan
        {
            rule_set = getTags <| __geositeRuleset.japan;
            domain_suffix = [ ".jp" ];
            outbound = __groups.proxy_japan.tag;
        }

        # Europe
        {
            rule_set = getTags <| __geositeRuleset.europe;
            domain_suffix = [];
            outbound = __groups.proxy_europe.tag;
        }

        # US: explicitly-listed us destinations ride the us nodes.
        # geoip-us matching is deliberately NOT used: the phone's
        # flows arrive as bare ips, and herding them into a regional
        # selector breaks on any single-family default member -- they
        # belong on the dual-stack default (final)
        {
            domain_suffix = [
                "f95zone.to"
                "coverartarchive.org"
            ];
            outbound = __groups.proxy_us.tag;
        }

        # China ips: the ip fallback for the china domain rules
        # above. everything else falls through to `final` (Proxy).
        {
            rule_set = [ __geoipRuleset.cn.tag ];
            outbound = __outs.direct.tag;
        }
    ];

}
|> (val: with builtins; {
    attr = val;
    names =
        # select attrnames which are not started with "__"
        filter ( n: ( match "^__.*" n ) == [] )
        <| attrNames val;
})
|> (val: with val;
    builtins.removeAttrs attr names)

# vim: ft=nix:nowrap:
