{ lib, pkgs, config, ... }:

let

    inherit (config.lore)
        ports
        domains
        apps
    ;
    umi = config.lore.machines.umi;

    clashApiAddr = "127.0.0.1:${toString ports.clashApi}";

in {

    disabledModules = [
        "services/networking/sing-box.nix"
    ];

    imports = [
        ./dashboard.nix
        ./tproxy.nix
    ];

    # commercial outbound secrets only; policy is plaintext
    # (policy.nix). conf--sing.nix.sops is unreferenced, kept
    # for rollback.
    sops.secrets =
        let singService = config.systemd.services."sing-box".name; in
        {
            secrets--sing = {
                sopsFile = ./secrets--sing.nix.sops;
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
                lanIp = "${umi.static_ip}";
                tailnetIp = "${umi.tailnet_ip}";
                noproxyDomains = ${noproxy};
                # N.B. bind_interface to tailscale0
                tailnetDomains = ${tailnetDomains};
                clashApiAddr = "${clashApiAddr}";

                # :: string -> path
                geositeDataOf = name:
                    let pkg = "${pkgs.sing-geosite}"; in
                    let dir = "''${pkg}/share/sing-box/rule-set"; in
                    "''${dir}/geosite-''${name}.srs";

                # :: string -> path
                geoipDataOf = name:
                    let pkg = "${pkgs.sing-geoip}"; in
                    let dir = "''${pkg}/share/sing-box/rule-set"; in
                    "''${dir}/geoip-''${name}.srs";
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
                --arg "secretsFile" "$CREDENTIALS_DIRECTORY/private_secrets" \
                "${./policy.nix}" \
            > "$conf"
            # restart stops the old listener before the new
            # ExecStart, so this cannot prevent downtime; it turns
            # config errors into a clean unit failure instead of an
            # exec crash-loop
            sing-box check --config "$conf"
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
                [ "private_secrets:${secrets.secrets--sing.path}" ];
            DynamicUser = true;
            Nice = -10;
            # the dns inbound binds the tailnet address, which races
            # tailscale0 at boot: unlimited retries at 2s spacing
            # (the start-rate limit is disabled below)
            Restart = "on-failure";
            RestartSec = "2s";
            AmbientCapabilities = [
                "CAP_NET_ADMIN"
                "CAP_NET_BIND_SERVICE"
            ];
        };
        # [Service]-level StartLimitIntervalSec is ignored by systemd;
        # the start-rate burst limit is a unit-level knob
        startLimitIntervalSec = 0;
        # nss-systemd synthesizes the DynamicUser's passwd entry only
        # while the unit is registered, so home lookups race it and
        # intermittently fail ("cannot determine user's home
        # directory"): explicit homes skip the lookup
        environment = {
            HOME = "%S/sing-box";
            XDG_CACHE_HOME = "%C";
            XDG_STATE_HOME = "%S/sing-box";
        };
        wantedBy = [ "multi-user.target" ];
        requires = [ "sops-install-secrets.service" ];
        after = [ "sops-install-secrets.service" ];
    };

    # tcp only: the SOCKS UDP association is deliberately not
    # exposed. tproxy traffic keeps its original daddr/dport, so
    # tproxy.nix accepts it by mark instead of a port here. no v6:
    # the mixed inbound is v4-only (loopback + lan)
    networking.firewall.extraInputRules =
        let inherit (config.lore.network) lan4 tailnet4; in
        ''
            ip saddr { ${lan4}, ${tailnet4} } tcp dport ${toString ports.proxy} counter accept
        '';

}
