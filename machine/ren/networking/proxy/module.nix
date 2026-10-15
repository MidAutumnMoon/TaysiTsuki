{ lib, pkgs, config, ... }:

let

    inherit (config.lore)
        ports
        domains
        apps
    ;

    clashApiAddr = "127.0.0.1:${toString ports.clashApi}";

in {

    disabledModules = [
        "services/networking/sing-box.nix"
    ];

    imports = [
        ./dashboard.nix
        ./tproxy.nix
    ];

    sops.secrets =
        let singService = config.systemd.services."sing-box".name; in
        {
            conf--sing = {
                sopsFile = ./conf--sing.nix.sops;
                format = "binary";
                restartUnits = [ singService ];
            };
        };

    passthru.singboxLore =
        let
            noproxy = with lib;
                apps.homelab
                |> attrValues |> map (val: val.fqdn)
                |> appendElem "local"
                |> concatMapStringsSep " " (v: "\"${v}\"")
                |> (v: "[ ${v} ]");
            tailnetDomains = with lib;
                apps.tailnet
                |> attrValues |> map (val: val.fqdn)
                |> appendElem domains.im_418_ts
                |> concatMapStringsSep " " (v: "\"${v}\"")
                |> (v: "[ ${v} ]");
        in pkgs.writeText "sing-box-lore.nix" ''
            {
                listenPort = ${toString ports.proxy};
                tproxyPort = ${toString ports.tproxy};
                noproxyDomains = ${noproxy};
                # N.B. bind_interface to tailscale0
                tailnetDomains = ${tailnetDomains};
                clashApiAddr = "${clashApiAddr}";

                # :: string -> path
                # Return the path of geosite data of $name
                geositeDataOf = name:
                    let pkg = "${pkgs.sing-geosite}"; in
                    let dir = "''${pkg}/share/sing-box/rule-set"; in
                    "''${dir}/geosite-''${name}.srs";
            }
            # vim: ft=nix:
        '';

    systemd.services."sing-box" = {
        path = [
            config.nix.package
            pkgs.tsuki.sing-box
        ];
        script = /* sh */ ''
            conf="$RUNTIME_DIRECTORY/config.json"
            nix-instantiate \
                --eval --strict --json \
                --arg "loreFile" "${config.passthru.singboxLore}" \
                "$CREDENTIALS_DIRECTORY/private_config" \
            > "$conf"
            exec sing-box run \
                --directory "$STATE_DIRECTORY" \
                --config "$conf"
        '';
        serviceConfig = {
            StateDirectory = "sing-box";
            RuntimeDirectory = "sing-box";
            CacheDirectory = "sing-box";
            LoadCredential =
                let inherit (config.sops) secrets; in
                [ "private_config:${secrets.conf--sing.path}" ];
            DynamicUser = true;
            Nice = -10;
            AmbientCapabilities = [
                "CAP_NET_ADMIN"
                "CAP_NET_BIND_SERVICE"
            ];
        };
        # useHardening = true;
        wantedBy = [ "multi-user.target" ];
        requires = [ "sops-install-secrets.service" ];
        after = [ "sops-install-secrets.service" ];
    };

    # the proxy port serves trusted devices only; the SOCKS UDP
    # association is deliberately not exposed. tproxy'd packets
    # still traverse the input chain with their original daddr/
    # dport: from trusted ranges only the common ports (53/80/443,
    # scoped in their own modules) accept them, and that
    # arbitrary-port gap is pre-existing and out of scope
    networking.firewall.extraInputRules =
        let inherit (config.lore.network) lan4 lan6 tailnet4 tailnet6; in
        ''
            ip saddr { ${lan4}, ${tailnet4} } tcp dport ${toString ports.proxy} counter accept
            ip6 saddr { ${lan6}, ${tailnet6} } tcp dport ${toString ports.proxy} counter accept
        '';

}
