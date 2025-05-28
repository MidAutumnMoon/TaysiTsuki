{ lib, pkgs, config, ... }:

let

    inherit ( config.lore )
        ports
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
        };
        wantedBy = [ "multi-user.target" ];
        requires = [ "sops-install-secrets.service" ];
        after = [ "sops-install-secrets.service" ];
    };

    services.caddy.virtualHosts."*.home.lan" = {
        extraConfig = ''
            @clashApi host clash.home.lan
            handle @clashApi {
                handle_path /api* {
                    reverse_proxy http://${controllerListen}
                }
                root * ${pkgs.tsuki.metacubexd}
                file_server
            }
        '';
    };

    services.caddy.virtualHosts."http://wpad" =
        let
            wpad = pkgs.writeTextDir "wpad.dat" /*js*/ ''
                function FindProxyForURL( url, host ) {
                    return "PROXY ren.home.lan:${toString ports.proxyPort}";
                }
            '';
        in {
            listenAddresses = [ "[::]" ];
            logFormat = ''
                output stderr
            '';
            extraConfig = ''
                root * ${wpad}
                file_server browse
            '';
        };

    networking.firewall = {
        allowedTCPPorts = [ ports.proxyPort ];
        allowedUDPPorts = [ ports.proxyPort ];
    };

    boot.kernel.sysctl = {
        "net.ipv4.tcp_fastopen" = "3";
    };

}
