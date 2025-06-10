{ lib, ... }:

let

    inherit ( lib )
        mkOption
        types
    ;

in

{ options.lore = {

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

    domains = mkOption {
        readOnly = true;
        type = with types; attrsOf ( submodule {
            freeformType = attrsOf str;
            options.name = mkOption {
                type = str;
                readOnly = true;
            };
        } );
    };

    apps = mkOption {
        readOnly = true;
        description = "Services (namespaced)";
        type = types.attrsOf <| types.attrsOf <| types.submodule
            ( { config, name, ... }: {
                options.subdomain = mkOption {
                    type = types.str;
                    readOnly = true;
                };
                options.domain = mkOption {
                    type = types.str;
                    readOnly = true;
                };
                options.fqdn = mkOption {
                    type = types.str;
                    readOnly = true;
                    default = with config; "${subdomain}.${domain}";
                    description = "FQDN of the service";
                };
                options.cname = mkOption {
                    type = types.str;
                    readOnly = true;
                };
                options.ip = mkOption {
                    type = types.str;
                    readOnly = true;
                    description = "IPv4 address";
                };
                options.ip6 = mkOption {
                    type = types.str;
                    readOnly = true;
                    description = "IPv6 address";
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

    utils = mkOption {
        type = with types; attrsOf anything;
        readOnly = true;
        description = "Some place to store tools";
    };

}; }
