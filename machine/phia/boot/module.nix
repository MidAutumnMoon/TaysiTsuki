{ lib, pkgs, ... }:

{

    boot.initrd.availableKernelModules = [
        "ahci"
        "xhci_pci"
        "usbhid"
        "usb_storage"
        "sd_mod"
    ];

    boot.kernelPackages = pkgs.linuxPackages;

    boot.loader = {
        systemd-boot.enable = true;
        efi.canTouchEfiVariables = true;
    };

    boot.kernelModules = [ "kvm-intel" ];

}
