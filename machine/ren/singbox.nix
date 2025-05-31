{ lib, pkgs, config, ... }:

let

    inherit ( config.lore )
        ports
        domains
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

    # cue > nix lol
    passthru.sing-pubconf = pkgs.writeText "sing-pubconf.cue" /*cue*/ ''
        package sing
        #listenPort: number
        #listenPort: ${toString ports.proxyPort}

        #hysteriaCert: string @tag( hysteriaCert )

        // Some cue dark magic
        // #geositePath & { _, #name: "ads" } evals to the path :)
        #geositePath: {
            #name: string // input
            #pkg: "${pkgs.sing-geosite}"
            #rulesetDir: "\(#pkg)/share/sing-box/rule-set"
            "\(#rulesetDir)/geosite-\(#name).srs"
        }

        #noproxyDomains:
            [
                "${domains.internal}",
                "${domains.tailscale}",
                ${
                    homelab
                    |> lib.attrValues
                    |> map ( it: ''"${it.name}"'' ) # quote is important
                    |> lib.concatStringsSep ", "
                }
            ]

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

    services.caddy.virtualHosts."teapot".extraConfig =
        let
            # TODO: no proxy internal domains
            wpad = pkgs.writeTextDir "wpad.dat" /*js*/ ''
                function FindProxyForURL( url, host ) {
                    return "PROXY ren.${domains.internal}:${toString ports.proxyPort}";
                }
            '';
        in ''
            @clash_api host ${homelab.clash_dashboard.name}
            handle @clash_api {
                handle_path /api* {
                    reverse_proxy http://${controllerListen}
                }
                root * ${pkgs.tsuki.metacubexd}
                file_server
            }

            @wpad host ${homelab.wpad.name}
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
