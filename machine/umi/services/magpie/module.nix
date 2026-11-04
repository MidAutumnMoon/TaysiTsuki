{ config, lib, pkgs, ... }:

let

    inherit (config) lore;

    inherit (lore) ports apps;

    fqdn = apps.homelab.magpie.fqdn;

    stateDir = "/var/lib/magpie";

    gatewayAddr = "127.0.0.1:${toString ports.magpieGateway}";
    webAddr = "127.0.0.1:${toString ports.magpieWeb}";

in
{

    users.groups.magpie = { };

    users.users.magpie = {
        isSystemUser = true;
        group = "magpie";
        home = "${stateDir}/home";
    };

    sops.secrets."magpie--web-key" = {
        sopsFile = ./secrets.sops.yml;
        key = "web_key";
        owner = "magpie";
        group = "magpie";
        mode = "0400";
        restartUnits = [ "magpie.service" ];
    };

    sops.templates."magpie-env".content = ''
        MAGPIE_WEB_KEY=${config.sops.placeholder."magpie--web-key"}
    '';

    systemd.services.magpie = {
        description = "magpie model gateway";
        wantedBy = [ "multi-user.target" ];
        wants = [ "network-online.target" ];
        after = [
            "network-online.target"
            "sops-install-secrets.service"
        ];
        requires = [ "sops-install-secrets.service" ];

        environment =
            config.networking.proxy.envVars
            // {
                HOME = "${stateDir}/home";
                XDG_CONFIG_HOME = "${stateDir}/config";
                XDG_CACHE_HOME = "${stateDir}/cache";
                XDG_DATA_HOME = "${stateDir}/data";
                XDG_STATE_HOME = "${stateDir}/state";
                MAGPIE_ADDR = gatewayAddr;
                MAGPIE_PUBLIC_URL = "https://${fqdn}";
                MAGPIE_BUN = "${pkgs.bun}/bin/bun";
                # the CLIs some subscriptions install are glibc
                # binaries, run through nix-ld
                NIX_LD = config.environment.variables.NIX_LD;
                NIX_LD_LIBRARY_PATH =
                    config.environment.variables.NIX_LD_LIBRARY_PATH;
                PATH = lib.mkForce (
                    lib.makeBinPath [
                        pkgs.bash
                        pkgs.coreutils
                        pkgs.curl
                        pkgs.git
                        pkgs.openssl
                    ]
                    + ":/run/current-system/sw/bin"
                );
            };

        serviceConfig = {
            User = "magpie";
            Group = "magpie";
            StateDirectory = [
                "magpie"
                "magpie/home"
                "magpie/config"
                "magpie/cache"
                "magpie/data"
                "magpie/state"
            ];
            StateDirectoryMode = "0700";
            WorkingDirectory = stateDir;
            EnvironmentFile = config.sops.templates."magpie-env".path;
            ExecStart = "${lib.getExe pkgs.tsuki.magpie} serve --web=${webAddr}";
            Restart = "on-failure";
            RestartSec = "5s";
            UMask = "0077";

            NoNewPrivileges = true;
            ProtectSystem = "strict";
            ProtectHome = true;
            PrivateTmp = true;
            PrivateDevices = true;
            ProtectClock = true;
            ProtectHostname = true;
            ProtectKernelTunables = true;
            ProtectKernelModules = true;
            ProtectKernelLogs = true;
            ProtectControlGroups = true;
            RestrictSUIDSGID = true;
            LockPersonality = true;
            SystemCallArchitectures = "native";
            # no MemoryDenyWriteExecute: Bun and some agent CLIs JIT
        };
    };

    services.caddy.virtualHosts."im_418".extraConfig = ''
        @magpie host ${fqdn}
        handle @magpie {
            reverse_proxy http://${webAddr}
        }
    '';

}
