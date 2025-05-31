{ lib, config, ... }:

let

    inherit ( lib )
        mkOption
        types
    ;

    sharedWithTf = lib.importJSON ./shared.json;

in {

    options.lore = {
        pubkeys = mkOption {
            type = types.attrsOf types.str;
            readOnly = true;
        };
        pubkeyList = mkOption {
            type = types.listOf types.str;
            default = builtins.attrValues config.lore.pubkeys;
            readOnly = true;
        };

        ports = mkOption {
            type = types.attrsOf types.port;
            description = "Pre-allocated ports";
            readOnly = true;
        };

        domains = mkOption {
            type = with types; attrsOf str;
            readOnly = true;
        };

        services = mkOption {
            type = with types; attrsOf <| submodule {
                options.name = mkOption { type = str; };
                options.host = mkOption { type = str; };
            };
            readOnly = true;
        };
    };

    config.lore = rec {

        pubkeys = {
            teapot = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEyX4qdUuwPEqQa+QaR8/0MubpfB9rHbpGAH+yEM9kxM me@418.im";
        };

        ports = {
            proxyPort = 7890;
            torrent = 9094;
            qbitwebui = 9095;
            dnscryptWebui = 9096;
            clashApi = 9097;
            dns =
                with sharedWithTf;
                assert dns_port == 9098; # avoid silly mistakes
                dns_port;
        };

        domains = rec {
            teapot = "418.im";
            internal = "in.${teapot}";
            tailnet = sharedWithTf.tailnet;
        };

        services = {
            router = with domains; {
                name = "router.${teapot}";
                host = "router.${internal}";
            };
        };

    };

}

# vim: nowrap:
