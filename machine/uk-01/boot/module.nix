{ lib, pkgs, ... }:

{

    boot = {
        loader.grub.enable = true;
        kernelPackages = lib.mkForce pkgs.linuxPackages_cachyos-server;
    };

}
