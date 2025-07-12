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

    controllerListen = "127.0.0.1:${toString ports.clashApi}";

in

{

    sops.secrets = rec {
        conf--sing = {
            sopsFile = ./secrets/conf--sing.cue.sops;
            format = "binary";
            restartUnits = [ "sing-box.service" ];
        };
        cert--hysteria = {
            key = "ca";
            sopsFile = ./secrets/cert--hysteria.yml;
            restartUnits = conf--sing.restartUnits;
        };
    };

    # NOTE: actually using nix may be a smarter idea
    # Pass information from within nixos onto sing-box without
    # hardcode them in the private config.
    passthru.sing-pubconf =
        let
            inherit ( domains ) im_418;
            quote = it: ''"${it}"'';
            noproxy_domains =
                homelab
                |> lib.attrValues
                |> map ( it: it.fqdn )
                |> lib.appendElem "local"
                |> lib.appendElem "${im_418.tailscale_zone}.${im_418.name}"
                |> lib.concatMapStringsSep ", " quote;
        in
        pkgs.writeText "sing-pubconf.cue" /*cue*/ ''
            package sing
            #listenPort: number & ${toString ports.proxyPort}
            #hysteriaCert: string @tag( hysteriaCert )
            #noproxyDomains: [ ${noproxy_domains} ]

            // Some cue dark magic
            // #geositePath & { _, #name: "ads" } evals to the path :)
            #geositePath: {
                #name: string // input
                #pkg: "${pkgs.sing-geosite}"
                #rulesetDir: "\(#pkg)/share/sing-box/rule-set"
                "\(#rulesetDir)/geosite-\(#name).srs"
            }

            experimental: {
                cache_file: enabled: true
                clash_api: {
                    external_controller: "${controllerListen}"
                    secret: ""
                }
            }
        '';

    systemd.services."sing-box" = let
        # N.B. .cue is essential, other cue won't recognize it
        sing_cue = "conf--sing.cue";
        cert = "cert--hysteria";
    in {
        path = with pkgs; [
            cue
            tsuki.sing-box
        ];
        script = /* sh */ ''
            export HOME="$CACHE_DIRECTORY"
            CONFIG="$RUNTIME_DIRECTORY/config.json"
            cue export --out json \
                '${config.passthru.sing-pubconf}' \
                "$CREDENTIALS_DIRECTORY/${sing_cue}" \
                --inject hysteriaCert="$CREDENTIALS_DIRECTORY/${cert}" \
                --force --outfile "$CONFIG"
            sing-box run \
                --directory "$STATE_DIRECTORY" \
                --config "$CONFIG"
        '';
        serviceConfig = {
            StateDirectory = "sing-box";
            RuntimeDirectory = "sing-box";
            CacheDirectory = "sing-box";
            LoadCredential =
                let inherit ( config.sops ) secrets; in
                [
                    "${sing_cue}:${secrets.conf--sing.path}"
                    "${cert}:${secrets.cert--hysteria.path}"
                ];
            DynamicUser = true;
            RemoveIPC = true;
            NoNewPrivileges = true;
            CapabilityBoundingSet = "";
            ProtectClock = true;
            ProtectKernelLogs = true;
            ProtectControlGroups = true;
            ProtectKernelModules = true;
            ProtectHostname = true;
            ProtectKernelTunables = true;
            ProtectSystem = "strict";
            SystemCallArchitectures = "native";
            MemoryDenyWriteExecute = true;
            RestrictNamespaces = true;
            RestrictSUIDSGID = true;
            RestrictRealtime = true;
            LockPersonality = true;
            SystemCallFilter = "@system-service";
            ProtectProc = "invisible";
            ProcSubset = "pid";
            PrivateMounts = true;
            RestrictAddressFamilies = [
                "AF_UNIX" "AF_PACKET" "AF_NETLINK"
                "AF_INET" "AF_INET6"
            ];
        };
        wantedBy = [ "multi-user.target" ];
        requires = [ "sops-install-secrets.service" ];
        after = [ "sops-install-secrets.service" ];
    };

    services.caddy.virtualHosts."im_418".extraConfig =
        let
            wpad = pkgs.writeTextDir "wpad.dat" /*js*/ ''
                function FindProxyForURL( url, host ) {
                    return "PROXY ${homelab.proxy.fqdn}:${toString ports.proxyPort}";
                }
            '';
        in ''
            @clash_api host ${homelab.clash_dashboard.fqdn}
            handle @clash_api {
                handle_path /api* {
                    reverse_proxy http://${controllerListen}
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
        allowedTCPPorts = [ ports.proxyPort ];
        allowedUDPPorts = [ ports.proxyPort ];
    };

    boot.kernel.sysctl = {
        "net.ipv4.tcp_fastopen" = "3";
    };

}
