{ lib, ... }:

let

    inherit ( lib )
        mkOption
        types
    ;

    appSubmod = types.submodule {
        options.fqdn = mkOption {
            type = types.str;
            readOnly = true;
            description = "The domain the service is hosted on";
        };
        options.cname_target = mkOption {
            type = with types; nullOr str;
            default = null;
            description = "The `fqdn` is CNAME, and this is its target";
        };
        # options.ipv4 = ...
    };

    domainDeclSubmod = types.submodule {
        freeformType = with types; attrsOf str;
        options.name = mkOption {
            type = types.str;
            readOnly = true;
            description = "The base domain name";
        };
    };

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
                } );
        };

        ports = mkOption {
            type = types.attrsOf types.port;
            readOnly = true;
            description = "Pre-allocated ports";
        };

        domains = mkOption {
            type = with types; attrsOf domainDeclSubmod;
            readOnly = true;
        };

        apps = mkOption {
            type = with types; attrsOf ( attrsOf appSubmod );
            readOnly = true;
            description = "Namespaces of services";
            example = ''
                apps.homelab = {
                    moonbase = { ... };
                    techbar = { ... };
                };
            '';
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
