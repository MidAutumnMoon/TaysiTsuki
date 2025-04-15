{ config, lib, ... }:

{

    services.openssh = {
        enable = true;
        settings = rec {
            PermitRootLogin = "prohibit-password";
            PasswordAuthentication = false;
            KbdInteractiveAuthentication = false;
            Ciphers = [ "chacha20-poly1305@openssh.com" ];
            HostKeyAlgorithms = "ssh-ed25519-cert-v01@openssh.com,ssh-ed25519";
            PubkeyAcceptedAlgorithms = HostKeyAlgorithms;
            KexAlgorithms = [
                "mlkem768x25519-sha256"
                # remove once ssh on stable Debian reaches >= 9.9
                "sntrup761x25519-sha512@openssh.com"
            ];
            Macs = [ "hmac-sha2-512-etm@openssh.com" ];
        };
    };

    programs.ssh = let
        sshd = config.services.openssh.settings;
    in rec {
        macs = sshd.Macs;
        ciphers = sshd.Ciphers;
        hostKeyAlgorithms = sshd.HostKeyAlgorithms |> lib.splitString ",";
        pubkeyAcceptedKeyTypes = hostKeyAlgorithms;
        kexAlgorithms = sshd.KexAlgorithms;
    };

}

