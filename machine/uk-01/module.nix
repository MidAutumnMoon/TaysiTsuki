{ modulesPath, ... }:

{

    imports = [
        (modulesPath + "/profiles/qemu-guest.nix")
        ./disko.nix
    ];

    boot = {
        loader.grub.enable = true;
    };

    fonts.fontconfig.enable = false;
    documentation.man.enable = false;

    sops.age.sshKeyPaths = [
        "/etc/ssh/ssh_host_ed25519_key"
    ];

}
