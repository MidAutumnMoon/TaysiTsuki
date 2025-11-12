{ lib, config, pkgs, ... }:

let

    localDomains =
        let
            # TODO: handle conflict names?
            localApps = with config.lore.apps; homelab // tailnet;
            try = app: attr: (builtins.tryEval (app.${attr})).success;
            fmt = app:
                if try app "ip" then "A ${app.ip}" else
                if try app "ip6" then "AAAA ${app.ip6}" else
                if try app "cname" then "CNAME ${app.cname}"
                else builtins.throw "[BUG] invalid app ${app.fqdn}";
            localData = localApps
                |> lib.attrValues
                |> map (app: ''${app.fqdn}. IN ${fmt app}'');
        in pkgs.writeText "local-domains" ''
            $TTL 69
            example.com. IN SOA a b (1 7200 3600 3600 3600)
            ${lib.join "\n" localData}
        '';

    corednsIface = "enp3s0";
    corednsService = config.systemd.services.coredns.name;

in

{

    networking.firewall = {
        allowedTCPPorts = [ 53 ];
        allowedUDPPorts = [ 53 ];
    };

    services.avahi2dns.enable = true;

    # coredns provides homelab domain resolution
    services.coredns = {
        enable = true;
        package = pkgs.tsuki.coredns;
    };

    services.coredns.config =
        let
            avahi2dnsPort = toString config.services.avahi2dns.port;
            dnscryptPort = toString config.lore.ports.dnscryptLocal;
        in ''
            (the_conf) {
                log
                file ${localDomains} {
                    # at least v1.12.2
                    fallthrough
                }
                forward local 127.0.0.1:${avahi2dnsPort}
                forward . [::1]:${dnscryptPort}
                cache 60 {
                    disable success local
                    disable denial local
                }
            }
            .:53 {
                bind ${corednsIface}
                import the_conf
            }
            .:53 {
                bind 127.0.0.1 ::1
                import the_conf
            }
        '';

    # When coredns launches, the interface may not yet have addresses,
    # which causes coredns unable to handle incoming requests.
    # This service reloads coredns on address changes.
    #
    # ## Why not systemd-dispatch?
    #
    # It's a simple Python script, but for some reason it also depends
    # on glib :/
    systemd.services."coredns-reload-on-changes" = {
        unitConfig = {
            # AI: learnt sys-subsystem-*.device
            BindsTo = "sys-subsystem-net-devices-${corednsIface}.device";
            Requires = corednsService;
            After = [
                "sys-subsystem-net-devices-${corednsIface}.device"
                corednsService
            ];
        };
        serviceConfig = {
            Type = "simple";
            Restart = "always";
            RestartSec = "5s";
        };
        wantedBy = [ "multi-user.target" ];
        path = [
            pkgs.iproute2
            config.systemd.package
        ];
        script = ''
            # AI: learnt "ip monitor"
            ip -4 -6 mon a dev ${corednsIface} | while read -r _;
            do
                echo "Address changes detected, reload coredns"
                systemctl reload "${corednsService}"
            done
        '';
    };

    # dnscrypt-proxy resolves internet names
    services.dnscrypt-proxy = {
        enable = true;
        upstreamDefaults = false;
        package = pkgs.tsuki.dnscrypt;
        settings = rec {
            listen_addresses = [
                "[::1]:${toString config.lore.ports.dnscryptLocal}"
            ];
            server_names = lib.attrNames static;
            static = {
                "doh-pub".stamp =
                    "sdns://AgcAAAAAAAAAAAAHZG9oLnB1YgovZG5zLXF1ZXJ5";
                "alidns".stamp =
                    "sdns://AgcAAAAAAAAAAAAOZG5zLmFsaWRucy5jb20KL2Rucy1xdWVyeQ";
            };
            bootstrap_resolvers = [ "223.5.5.5:53" ];
            netprobe_address = "223.5.5.5:53";
            cache = false;
            blocked_names.blocked_names_file =
                "${pkgs.tsuki.adblocklist}/blocklist-dnscrypt.txt";
        };
    };

}
