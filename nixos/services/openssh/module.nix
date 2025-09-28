{ pkgs, ... }:

{

    services.openssh.enable = true;
    services.openssh.package = pkgs.openssh_hpn;

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
