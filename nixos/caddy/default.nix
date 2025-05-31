{ pkgs, config, lib, ... }:

let

    caddyCfg = config.services.caddy;

    proxyCfg = config.networking.proxy;

in

lib.mkIf caddyCfg.enable {

    services.caddy.package = pkgs.tsuki.caddy;

    systemd.services.caddy = {
        serviceConfig = {
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
                "AF_UNIX"
                "AF_INET"
                "AF_INET6"
            ];
        };
        environment =
            with proxyCfg;
            lib.mkIf ( envVars != {} ) envVars;
    };

}
