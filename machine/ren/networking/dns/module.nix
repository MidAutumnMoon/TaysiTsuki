{ lib, config, pkgs, ... }:

let

    umi = config.lore.machines.umi;
    umiFqdn = with config.lore.domains; "${umi.hostname}.${im_418}";

    cloakRules =
        let
            localApps = with config.lore.apps; homelab // tailnet;
            try = app: attr: (builtins.tryEval (app.${attr})).success;
            # apps aliased to umi carry its addresses directly: name
            # targets are resolved upstream, which cannot see umi
            appLines = app:
                if try app "cname" && app.cname == umiFqdn then
                    map (ip: "=${app.fqdn} ${ip}")
                        [ umi.static_ip umi.static_ip6 ]
                else if try app "ip" then [ "=${app.fqdn} ${app.ip}" ]
                else if try app "ip6" then [ "=${app.fqdn} ${app.ip6}" ]
                else if try app "cname" then [ "=${app.fqdn} ${app.cname}" ]
                else builtins.throw "[BUG] invalid app ${app.fqdn}";
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

    networking.firewall = {
        allowedTCPPorts = [ 53 ];
        allowedUDPPorts = [ 53 ];
    };

    # dnscrypt-proxy resolves internet names and serves lan records
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
            # cloaking is flat upstream: `cloaking_rules` is the file path,
            # `cloak_ttl` a top-level key (unlike blocked_names)
            cloaking_rules = "${cloakRules}";
            cloak_ttl = 60;
            # sinks .local etc. locally; the Go default is false and
            # upstreamDefaults = false means the example config is not merged
            block_undelegated = true;
        };
    };

}
