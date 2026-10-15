{ lib, config, pkgs, ... }:

let

    inherit (config) lore;
    inherit (lore.apps) homelab;

    clashApiAddr = "127.0.0.1:${toString lore.ports.clashApi}";

in {

    services.caddy.virtualHosts."im_418".extraConfig = ''
        @clash_api {
            host ${homelab.clash_dashboard.fqdn}
            client_ip private_ranges
        }
        handle @clash_api {
            handle_path /api* {
                reverse_proxy http://${clashApiAddr}
            }
            root * ${pkgs.tsuki.metacubexd}
            file_server
        }
    '';

}
