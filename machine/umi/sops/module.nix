{
    sops.age.keyFile = "/var/lib/age.txt";

    sops.secrets = {
        ssh_ed25519_key.sopsFile = ./seed.yml;
        ssh_ed25519_pub.sopsFile = ./seed.yml;
    };
}
