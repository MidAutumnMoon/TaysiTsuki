{ lib, config, pkgs, ... }:

let

    umi = config.lore.machines.umi;
    umiFqdn = with config.lore.domains; "${umi.hostname}.${im_418}";

    cloakRules =
        let
            localApps = with config.lore.apps; homelab // tailnet;
            line = app: addr: "=${app.fqdn} ${addr}";
            # umi-aliased apps carry umi's addresses directly:
            # upstream resolvers cannot see umi's names
            appLines = app:
                if app.cname == umiFqdn then
                    map (line app) [ umi.static_ip umi.static_ip6 ]
                else
                    lib.optional (app.ip != null) (line app app.ip)
                    ++ lib.optional (app.ip6 != null) (line app app.ip6);
            machineLines =
                map (ip: "=${umiFqdn} ${ip}") [ umi.static_ip umi.static_ip6 ];
            lines = machineLines ++ (
                localApps
                |> lib.attrValues
                |> map appLines
                |> lib.concatLists);
        in pkgs.writeText "cloaking-rules" ''
            ${lib.join "\n" lines}
        '';

in

{

    networking.firewall.extraInputRules =
        let inherit (config.lore.network) lan4 lan6 tailnet4 tailnet6; in
        ''
            ip saddr { ${lan4}, ${tailnet4} } tcp dport 53 counter accept
            ip saddr { ${lan4}, ${tailnet4} } udp dport 53 counter accept
            ip6 saddr { ${lan6}, ${tailnet6} } tcp dport 53 counter accept
            ip6 saddr { ${lan6}, ${tailnet6} } udp dport 53 counter accept
        '';

    services.dnscrypt-proxy = {
        enable = true;
        upstreamDefaults = false;
        package = pkgs.tsuki.dnscrypt;
        settings = rec {
            listen_addresses = [
                "127.0.0.1:53"
                "[::1]:53"
                "${umi.static_ip}:53"
                "[${umi.static_ip6}]:53"
            ];
            server_names = lib.attrNames static;
            static = {
                "doh-pub".stamp =
                    "sdns://AgcAAAAAAAAAAAAHZG9oLnB1YgovZG5zLXF1ZXJ5";
                "alidns".stamp =
                    "sdns://AgcAAAAAAAAAAAAOZG5zLmFsaWRucy5jb20KL2Rucy1xdWVyeQ";
            };
            bootstrap_resolvers = [ "223.5.5.5:53" ];
            netprobe_address = "223.5.5.5:53";
            blocked_names.blocked_names_file =
                "${pkgs.tsuki.adblocklist}/blocklist-dnscrypt.txt";
            # upstream quirk: `cloak_ttl` is top-level, unlike
            # blocked_names' nesting
            cloaking_rules = "${cloakRules}";
            cloak_ttl = 60;
            # sinks .local etc.; the Go default is false and
            # upstreamDefaults = false skips the example config
            block_undelegated = true;
        };
    };

}
