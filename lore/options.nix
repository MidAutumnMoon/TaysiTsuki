{ lib, ... }:

let

    inherit ( lib )
        mkOption
        types
    ;

in

{
    options.lore = {

        pubkeys = mkOption {
            type = types.attrsOf types.str;
            readOnly = true;
            description = "Pool of pubkeys";
        };

        machines = mkOption {
            readOnly = true;
            description = "Shared information of NixOS machines";
            type = types.attrsOf <| types.submodule
                ( { name, config, ... }: {
                    options.hostname = mkOption {
                        type = types.str;
                        default = name;
                        description = "Plain hostname";
                    };
                    options.mdns = mkOption {
                        type = types.str;
                        default = "${config.hostname}.local";
                        description = "mDNS hostname";
                    };
                    options.static_ip = mkOption {
                        type = with types; str;
                        readOnly = true;
                    };
                    options.static_ip6 = mkOption {
                        type = with types; str;
                        readOnly = true;
                    };
                } );
        };

        ports = mkOption {
            type = types.attrsOf types.port;
            readOnly = true;
            description = "Pre-allocated ports";
        };

        apps = mkOption {
            readOnly = true;
            description = "Services (namespaced)";
            type = types.attrsOf <| types.attrsOf <| types.submodule
                ( { config, name, ... }: {
                    options.name = mkOption {
                        type = types.str;
                        default = name;
                    };
                    options.fqdn = mkOption {
                        type = types.str;
                        readOnly = true;
                        description = "FQDN of the service";
                    };
                    options.port = mkOption {
                        type = types.port;
                        readOnly = true;
                    };
                    options.fqdn_port = mkOption {
                        type = types.str;
                        readOnly = true;
                        default = "${config.fqdn}:${config.port}";
                    };
                    options.cname = mkOption {
                        type = types.str;
                        readOnly = true;
                    };
                    options.ip = mkOption {
                        type = types.str;
                        readOnly = true;
                    };
                } );
        };

        tsukiObservatory = mkOption {
            type = types.path;
            readOnly = true;
            description = ''
                Absolute path to this flake placed under homedir.
                NOT the path in /nix/store
            '';
        };

    };
}
