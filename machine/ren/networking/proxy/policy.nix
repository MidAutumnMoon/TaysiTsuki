{
    # :: path
    # :: path
    loreFile,
    secretsFile,
}:

# plaintext policy; the encrypted secrets file carries the
# commercial outbounds and the clash api secret. node tags are
# duplicated between the two on purpose: `sing-box check`
# validates schema only, and the nodeTags lookups make tag drift
# fail at evaluation

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

    __nodes = secrets.outbounds;
    nodeByName = listToAttrs <| map (o: { name = o.tag; value = o; }) __nodes;

    # :: [ string ] -> [ tag ]
    nodeTags = names: map (name: nodeByName.${name}.tag) names;

in rec {

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

    __dnsServers = {
        # dnscrypt on the loopback; type "local" would resolve via
        # the host stub -> quad-100 -> back here: a cycle
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
            # bootstrap via the local server, never quad-100: same cycle
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

    __inbounds = {
        # no wildcard bind: the firewall decides who is trusted
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
        # infra/tailscale.tf); the port-53 route rule hijacks it
        # into the dns engine
        tailnet_dns = {
            type = "direct";
            tag = "Inbound Tailnet Dns";
            listen = lore.tailnetIp;
            listen_port = 53;
        };
    };

    inbounds = attrValues __inbounds;

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

        # direct / tailscale are routing destinations, not proxy choices
        proxy_all_outbounds = {
            type = "selector";
            tag = "Proxy All Outbounds";
            outbounds = getTags __nodes;
        };
    };

    outbounds = attrValues <| __outs // __groups;

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

        {
            port = 53;
            action = "hijack-dns";
        }

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

        {
            rule_set = getTags <| __geositeRuleset.japan;
            domain_suffix = [ ".jp" ];
            outbound = __groups.proxy_japan.tag;
        }

        {
            rule_set = getTags <| __geositeRuleset.europe;
            domain_suffix = [];
            outbound = __groups.proxy_europe.tag;
        }

        # no geoip-us: the phone's bare-ip flows belong on the
        # dual-stack default (final)
        {
            domain_suffix = [
                "f95zone.to"
                "coverartarchive.org"
            ];
            outbound = __groups.proxy_us.tag;
        }

        {
            rule_set = [ __geoipRuleset.cn.tag ];
            outbound = __outs.direct.tag;
        }
    ];

}
|> (val: with builtins; {
    attr = val;
    names =
        filter ( n: ( match "^__.*" n ) == [] )
        <| attrNames val;
})
|> (val: with val;
    builtins.removeAttrs attr names)

# vim: ft=nix:nowrap:
