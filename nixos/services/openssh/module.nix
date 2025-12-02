{ lib, config, ... }:

lib.mkMerge [

    {
        services.openssh.enable = true;
        services.openssh.settings = rec {
            PermitRootLogin = "prohibit-password";
            PasswordAuthentication = false;
            KbdInteractiveAuthentication = false;
            Ciphers = [ "chacha20-poly1305@openssh.com" ];
            HostKeyAlgorithms = "ssh-ed25519-cert-v01@openssh.com,ssh-ed25519";
            PubkeyAcceptedAlgorithms = HostKeyAlgorithms;
            KexAlgorithms = [ "mlkem768x25519-sha256" ];
            Macs = [ "hmac-sha2-512-etm@openssh.com" ];
        };
    }

    (lib.mkIf (config ? sops) {
        services.openssh.hostKeys = lib.singleton {
            type = "ed25519";
            path = config.sops.secrets.ssh_ed25519_key.path;
        };

        systemd.suppressedSystemUnits = [
            config.systemd.services.sshd-keygen.name
        ];

        systemd.services.sshd =
            let
                sops = config.systemd.services."sops-install-secrets".name;
            in {
                requires = [ sops ];
                after = [ sops ];
            };
    })

]
