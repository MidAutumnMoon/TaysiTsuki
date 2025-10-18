{ lib, pkgs, ... }:

{

    boot.initrd.availableKernelModules = [
        "ahci"
        "xhci_pci"
        "usbhid"
        "usb_storage"
        "sd_mod"
    ];

    boot.kernelPackages = lib.mkForce pkgs.linuxPackages_cachyos-lts;

    boot.loader = {
        systemd-boot.enable = true;
        efi.canTouchEfiVariables = true;
    };

    boot.kernelModules = [ "kvm-intel" ];

}
