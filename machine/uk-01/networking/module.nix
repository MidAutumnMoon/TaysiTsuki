{ lib, pkgs, ... }:

{

    networking.useDHCP = lib.mkForce false;
    networking.hostName = "uk-01";

    systemd.services.mimic-cloud-init-network = {
        description = "Config network from cloud-init datasource";
        wantedBy = [
            "systemd-networkd.service"
            "multi-user.target"
        ];
        before = [
            "systemd-networkd.service"
            "dhcpcd.service"
        ];
        path = [
            pkgs.util-linux
        ];
        serviceConfig = {
            Type = "oneshot";
            ExecStart = "${lib.getExe pkgs.tsuki.mimic-cloud-init}";
            RemainAfterExit = "yes";
            TimeoutSec = "infinity";
        };
    };

}
