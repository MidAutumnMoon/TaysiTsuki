{ lib, config, pkgs, ... }:

let

    inherit (config) lore;
    inherit (lore.apps) homelab;

    clashApiAddr = "127.0.0.1:${toString lore.ports.clashApi}";

    wpad = with lore;
        pkgs.writeTextDir "wpad.dat" /*js*/ ''
            function FindProxyForURL( url, host ) {
                return "PROXY ${homelab.proxy.fqdn}:${toString ports.proxy}";
            }
        '';

in {

    services.caddy.virtualHosts."im_418".extraConfig = ''
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
            @dat path *.dat
            header @dat Content-Type application/x-ns-proxy-autoconfig
            root * ${wpad}
            file_server browse
        }
    '';

}
