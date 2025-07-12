{ config, lib, ... }:

let

    inherit ( lib )
        types
    ;

    # Options commented out will cause breakage, leave them here
    # for future referrence.
    hardeningOptions = {
        # Sandbox
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
        # PrivateNetwork = true;
        PrivateDevices = true;
        # PrivateIPC = true;
        # PrivatePIDs = true;
        # PrivateUsers = true;
        ProtectHostname = true;
        ProtectClock = true;
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectKernelLogs = true;
        ProtectControlGroups = true;
        RestrictAddressFamilies = [
            "AF_UNIX" "AF_PACKET" "AF_NETLINK"
            "AF_INET" "AF_INET6"
        ];
        # RestrictFileSystems = [];
        RestrictNamespaces = true;
        LockPersonality = true;
        MemoryDenyWriteExecute = true; # breaks jit
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        RemoveIPC = true;
        PrivateMounts = true;
        SystemCallFilter = [ "@system-service" ];
        SystemCallArchitectures = "native";
        ProtectProc = "invisible";
        ProcSubset = "pid";

        CapabilityBoundingSet = "";
        NoNewPrivileges = true;
        UMask = "0077";
    };

in

{

    options.systemd.services =
        let
            # Ref: https://github.com/NixOS/nixpkgs/issues/377827
            # Clever priority trick to allow the hardening config
            # to override the option defaults, but doesn't prevent
            # users from setting the options manually.
            betweenDefaultAndAssign = lib.mkOverride 999;
        in
        lib.mkOption {
            type = with types; attrsOf <| types.submodule
                ( { config, ... }: {
                    options.useHardening =
                        lib.mkEnableOption "Systemd service sandbox";
                    config = lib.mkIf config.useHardening {
                        serviceConfig =
                            lib.mapAttrs ( _n: betweenDefaultAndAssign )
                            hardeningOptions;
                    };
                } );
        };

    config = {
        systemd.extraConfig = ''
            DefaultTimeoutStopSec = 20s
        '';
    };

}
