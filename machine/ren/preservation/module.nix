{ config, ... }:

let

    persistDir = config.fileSystems."/persist".mountPoint;

in

{

    preservation.enable = true;

    preservation.preserveAt."${persistDir}" = {
        files = [
            { file = "/etc/ssh/ssh_host_ed25519_key"; mode = "0600"; }
            { file = "/etc/ssh/ssh_host_ed25519_key.pub"; mode = "0644"; }
            { file = "/etc/ssh/ssh_host_rsa_key"; mode = "0600"; }
            { file = "/etc/ssh/ssh_host_rsa_key.pub"; mode = "0644"; }
            { file = "/etc/machine-id"; mode = "0444"; inInitrd = true; }
        ];
        directories = [];
    };

    systemd.suppressedSystemUnits = [ "systemd-machine-id-commit.service" ];

}
