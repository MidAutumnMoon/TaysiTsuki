{ lib, pkgs, config, ... }:

{

    networking.useDHCP = lib.mkForce false;
    networking.hostName = "sjc-01";

    systemd.services.decrypt-network-config = {
        description = "Decrypt network config";
        wantedBy = [ "systemd-networkd.service" ];
        before = [ "systemd-networkd.service" ];
        path = with pkgs; [
            ssh-to-age
            sops
            bashInteractive
        ];
        serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = "yes";
            TimeoutSec = "infinity";
        };
        script = ''
            export SOPS_AGE_KEY_CMD='bash -c "
                ssh-to-age -private-key < ${
                    lib.head config.sops.age.sshKeyPaths
                }
            "'
            sops decrypt "${pkgs.copyPathToStore ./network.sops}" \
                > "/etc/systemd/network/10-enp0s3.network"
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
