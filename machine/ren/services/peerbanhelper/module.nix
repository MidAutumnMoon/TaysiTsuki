{ config, pkgs, lib, ... }:

let

    inherit (config.lore) ports apps;

    addr = "127.0.0.1";

in

{

    systemd.services."peerbanhelper" = {
        wantedBy = [ "multi-user.target" ];
        after = [
            "network-online.target"
            "tailscaled.service"
        ];
        wants = [ "network-online.target" ];
        script = ''
            touch "disable-update-check.txt"
            exec "${lib.getExe pkgs.jdk25_headless}" \
                -XX:SoftMaxHeapSize=512M \
                -XX:ZUncommitDelay=30 \
                -XX:+UseZGC -XX:+ZGenerational \
                -XX:+UseStringDeduplication \
                -Dpbh.release="nixos" \
                -Dpbh.serverAddress="${addr}" \
                -Dpbh.port="${toString ports.peerbanhelper}" \
                -Dpbh.logsdir="$LOGS_DIRECTORY" \
                -Dpbh.configdir="$STATE_DIRECTORY/config" \
                -Dpbh.datadir="$STATE_DIRECTORY/data" \
                -Dpbh.userLocale="zh-CN" \
                -jar "${pkgs.tsuki.peerbanhelper.jarPath}" nogui
        '';
        serviceConfig = rec {
            StateDirectory = "peerbanhelper";
            RuntimeDirectory = "peerbanhelper";
            LogsDirectory = "peerbanhelper";
            DynamicUser = true;
            MemoryDenyWriteExecute = lib.mkForce false; # for jit
            ProcSubset = lib.mkForce "all";
            WorkingDirectory = "%S/${StateDirectory}";
        };
        useHardening = true;
        description = "PeerBanHelper";
        environment = config.networking.proxy.envVars;
    };

    services.caddy.virtualHosts."im_418".extraConfig = ''
        @peerban host ${apps.homelab.peerban.fqdn}
        handle @peerban {
            reverse_proxy http://${addr}:${toString ports.peerbanhelper}
        }
    '';

}
