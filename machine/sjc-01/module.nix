{ modulesPath, ... }:

{

    imports = [
        (modulesPath + "/profiles/qemu-guest.nix")
        ./filesystem.nix
    ];

    fonts.fontconfig.enable = false;
    documentation.man.enable = false;

    sops.age.sshKeyPaths = [
        "/etc/ssh/ssh_host_ed25519_key"
    ];

}
