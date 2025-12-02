{ config, ... }:

let

    persistDir = config.fileSystems."/persist".mountPoint;

in {

    preservation.enable = false;

    preservation.preserveAt."${persistDir}" = {
        files = [
            { file = "/etc/ssh/ssh_host_ed25519_key"; mode = "0600"; }
            { file = "/etc/ssh/ssh_host_ed25519_key.pub"; mode = "0644"; }
            { file = "/etc/ssh/ssh_host_rsa_key"; mode = "0600"; }
            { file = "/etc/ssh/ssh_host_rsa_key.pub"; mode = "0644"; }
        ];
        directories = [];
    };

}
