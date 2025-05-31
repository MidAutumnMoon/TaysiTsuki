{ lib, config, ... }:

let

    inherit ( lib )
        mkOption
        types
    ;

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
        };

        domains = mkOption {
            type = with types; attrsOf str;
        };
    };

    config.lore = {

        pubkeys = {
            teapot = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEyX4qdUuwPEqQa+QaR8/0MubpfB9rHbpGAH+yEM9kxM me@418.im";
        };

        ports = {
            proxyPort = 7890;
            torrent = 9094;
            qbitwebui = 9095;
            dnscryptWebui = 9096;
            clashApi = 9097;
        };

        domains = rec {
            teapot = "418.im";
            internal = "in.${teapot}";
        };

    };

}

# vim: nowrap:
