{ lib, pkgs, config, ... }:

{

    networking.useDHCP = lib.mkForce false;
    networking.hostName = config.lore.machines.sjc-01.hostname;

    systemd.services.decrypt-network-config = {
        description = "Decrypt network config";
        wantedBy = [ "systemd-networkd.service" ];
        before = [ "systemd-networkd.service" ];
        path = with pkgs; [
            sops
            coreutils
        ];
        serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = "yes";
            TimeoutSec = "infinity";
        };
        script = ''
            export SOPS_AGE_KEY_CMD='cat ${config.sops.age.keyFile}'
            nf="/run/systemd/network/10-enp0s3.network"
            mkdir -p "$(dirname $nf)"
            sops decrypt "${pkgs.copyPathToStore ./network.sops}" > "$nf"
        '';
    };

    networking.nftables = {
        ruleset = lib.mkAfter ''
            include "/etc/nftables.d/*"
        '';
    };

    networking.firewall = {
        allowedUDPPortRanges = [
            # hysteria port hop
            {
                from = 38000;
                to = 41000;
            }
        ];
        allowedUDPPorts = [ 37105 ];
    };

}
