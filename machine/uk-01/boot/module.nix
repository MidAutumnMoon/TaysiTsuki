{ lib, pkgs, ... }:

{

    boot = {
        loader.grub.enable = true;
        kernelPackages = lib.mkForce pkgs.linuxPackages_cachyos-lts;
    };

    boot.kernelParams = [
        "possible_cpus=0"
    ];

}
