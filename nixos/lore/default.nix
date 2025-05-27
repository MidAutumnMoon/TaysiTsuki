{ lib, config, ... }:

let

    inherit (lib)
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
    };

    config = {

        lore.pubkeys = {
            teapot = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEyX4qdUuwPEqQa+QaR8/0MubpfB9rHbpGAH+yEM9kxM me@418.im";
        };

        lore.ports = {
            mihomo_listen = 7890;
            mihomo_api = 7895;
            torrent = 9094;
            qbitwebui = 9095;
            dnscryptWebui = 9096;
        };

    };

}

# vim: nowrap:
