{ lib, pkgs, config, ... }:

let

    inherit ( config.lore )
        ports
        domains
        apps
    ;

    inherit ( apps )
        homelab
    ;

    clashApiAddr = "127.0.0.1:${toString ports.clashApi}";

in

{

    disabledModules = [ "services/networking/sing-box.nix" ];

    sops.secrets =
        let singService = config.systemd.services."sing-box".name; in
        {
            conf--sing = {
                sopsFile = ./conf--sing.nix.sops;
                format = "binary";
                restartUnits = [ singService ];
            };
            cert--sing = {
                key = "ca";
                sopsFile = ./cert--sing.yml;
                restartUnits = [ singService ];
            };
        };

    passthru.singboxLore =
        let
            noproxy = with lib; with domains;
                apps.homelab
                |> attrValues |> map ( val: val.fqdn )
                |> appendElem "local"
                |> appendElem "${im_418.tailscale_zone}.${im_418.name}"
                |> concatMapStringsSep " " ( v: "\"${v}\"" )
                |> ( v: "[ ${v} ]" );
        in
        pkgs.writeText "sing-box-lore.nix"
        /*nix*/ ''
            {
                listenPort = ${toString ports.proxy};
                noproxyDomains = ${noproxy};
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
                --argstr "certPath" "$CREDENTIALS_DIRECTORY/cert" \
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
                let inherit ( config.sops ) secrets; in
                [
                    "private_config:${secrets.conf--sing.path}"
                    "cert:${secrets.cert--sing.path}"
                ];
            DynamicUser = true;
        };
        useHardening = true;
        wantedBy = [ "multi-user.target" ];
        requires = [ "sops-install-secrets.service" ];
        after = [ "sops-install-secrets.service" ];
        environment = {
            GC_NPROCS = "1";
        };
    };

    services.caddy.virtualHosts."im_418".extraConfig =
        let
            wpad = pkgs.writeTextDir "wpad.dat" /*js*/ ''
                function FindProxyForURL( url, host ) {
                    return "PROXY ${homelab.proxy.fqdn}:${toString ports.proxy}";
                }
            '';
        in ''
            @clash_api host ${homelab.clash_dashboard.fqdn}
            handle @clash_api {
                handle_path /api* {
                    reverse_proxy http://${clashApiAddr}
                }
                root * ${pkgs.tsuki.metacubexd}
                file_server
            }

            @wpad host ${homelab.wpad.fqdn}
            handle @wpad {
                root * ${wpad}
                file_server browse
            }
        '';

    networking.firewall = {
        allowedTCPPorts = [ ports.proxy ];
        allowedUDPPorts = [ ports.proxy ];
    };

    boot.kernel.sysctl = {
        "net.ipv4.tcp_fastopen" = "3";
    };

}
