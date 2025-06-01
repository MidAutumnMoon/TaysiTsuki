{ lib, config, flakes, ... }:

# TODO: remove the excessive amount of "teapot"

let

    inherit ( lib )
        mkOption
        types
    ;

    sharedWithTf = lib.importJSON ./shared.json;

in {

    imports = [
        ./options.nix
    ];

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

        homelab = mkOption {
            type = with types; attrsOf <| submodule {
                options.name = mkOption { type = str; };
                options.host = mkOption { type = str; };
            };
            readOnly = true;
        };

        tsukiObservatory = mkOption {
            type = types.path;
            readOnly = true;
        };
    };

    config.lore = rec {

        tsukiObservatory =
            "${config.users.users.teapot.home}/TaysiTsuki";

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
            teapot =
                with sharedWithTf;
                assert teapot_domain == "418.im"; teapot_domain;
            # N.B. manually set on openwrt :(
            internal = "in.${teapot}";
            # tailscale is the subdomain on 418.im
            # where tailnet is assigned from Tailscale the service
            tailscale = "tailscale.${teapot}";
            tailnet = sharedWithTf.tailnet;
        };

        homelab =
            assert flakes.self.nixosConfigurations ? ren;
            {
                router = with domains; {
                    name = "router.${teapot}";
                    host = "router.${internal}";
                };
                clash_dashboard = with domains; {
                    name = "clash.${teapot}";
                    host = "ren.${internal}";
                };
                dns_dashboard = with domains; {
                    name = "dnscrypt.${teapot}";
                    host = "ren.${internal}";
                };
                torrent_dashboard = with domains; {
                    name = "qbit.${teapot}";
                    host = "ren.${internal}";
                };
                wpad = with domains; {
                    name = "wpad.${teapot}";
                    host = "ren.${internal}";
                };
            };

    };

}

# vim: nowrap:
