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

    # only the commercial outbound secrets; policy is plaintext
    # (policy.nix). the old conf--sing.nix.sops stays around for
    # rollback.
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
                # Return the path of geosite data of $name
                geositeDataOf = name:
                    let pkg = "${pkgs.sing-geosite}"; in
                    let dir = "''${pkg}/share/sing-box/rule-set"; in
                    "''${dir}/geosite-''${name}.srs";

                # :: string -> path
                # Return the path of geoip data of $name
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
            # systemd stops the old listener before the new ExecStart
            # on restart, so the gate cannot prevent downtime; its
            # value is a clean unit failure with a clear journal
            # message instead of an exec crash-loop
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
            # survive the boot race with tailscale0 (the dns inbound
            # binds the tailnet address): unlimited retries at 2s
            # spacing -- a critical local listener must not die to a
            # start-rate burst limit
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
        # a DynamicUser has no passwd entry beyond what nss-systemd
        # synthesizes WHILE the unit is registered: any home lookup
        # races it and intermittently fails ("cannot determine user's
        # home directory", crash-loop until the race is lost enough
        # times). explicit homes remove the lookup entirely
        environment = {
            HOME = "%S/sing-box";
            XDG_CACHE_HOME = "%C";
            XDG_STATE_HOME = "%S/sing-box";
        };
        # useHardening = true;
        wantedBy = [ "multi-user.target" ];
        requires = [ "sops-install-secrets.service" ];
        after = [ "sops-install-secrets.service" ];
    };

    # the proxy port serves trusted devices only; the SOCKS UDP
    # association is deliberately not exposed. transparent tproxy
    # traffic opens no port here: tproxy.nix accepts it by mark
    # (which it owns) because such packets keep their original
    # daddr/dport through the input chain. no v6 accept: the mixed
    # inbound is v4-only (loopback + lan)
    networking.firewall.extraInputRules =
        let inherit (config.lore.network) lan4 tailnet4; in
        ''
            ip saddr { ${lan4}, ${tailnet4} } tcp dport ${toString ports.proxy} counter accept
        '';

}
