{ lib, pkgs, ... }:

{

    boot.loader = {
        systemd-boot.enable = true;
        efi.canTouchEfiVariables = true;
    };

    boot.initrd.availableKernelModules = [
        "nvme"
        "xhci_pci"
        "ahci"
        "usbhid"
        "usb_storage"
        "sd_mod"
    ];

    boot.kernelModules = [
        "amdgpu"
        "kvm-amd"
        "cifs"
    ];

    boot.kernelParams = [
        "amd_pstate=active"
        "preempt=full"
    ];

    boot.kernelPackages =
        pkgs.tsuki.cachyos.kernel.packages;

    boot.kernel.sysctl = {
        "kernel.dmesg_restrict" = 0;
    };

}
