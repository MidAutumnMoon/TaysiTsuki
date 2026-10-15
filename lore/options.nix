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
        description = "Shared information of machines on the network";
            type = types.attrsOf <| types.submodule
            ( { name, ... }: {
                options.hostname = mkOption {
                    type = types.str;
                    default = name;
                    description = "Plain hostname";
                };
                options.static_ip = mkOption {
                    type = with types; str;
                    readOnly = true;
                };
                options.static_ip6 = mkOption {
                    type = with types; str;
                    readOnly = true;
                };
                # not readOnly: a null default plus per-machine values
                # would count as multiple definitions. the consumers
                # (tproxy device sets) assert non-null themselves
                options.tailnet_ip = mkOption {
                    type = with types; nullOr str;
                    default = null;
                    description = "Tailscale IPv4 address";
                };
                options.tailnet_ip6 = mkOption {
                    type = with types; nullOr str;
                    default = null;
                    description = "Tailscale IPv6 address";
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
        type = with types; attrsOf str;
    };

    network = mkOption {
        readOnly = true;
        type = with types; attrsOf str;
        description = "Trusted network ranges, CIDR notation";
    };

    apps = mkOption {
        readOnly = true;
        description = "Services (namespaced)";
        type = types.attrsOf <| types.attrsOf <| types.submodule
            ( { config, ... }: {
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
                # local records carry explicit nulls so consumers
                # can read unset fields without eval errors
                options.cname = mkOption {
                    type = with types; nullOr str;
                    readOnly = true;
                };
                options.ip = mkOption {
                    type = with types; nullOr str;
                    readOnly = true;
                    description = "IPv4 address";
                };
                options.ip6 = mkOption {
                    type = with types; nullOr str;
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
