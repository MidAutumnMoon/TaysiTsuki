{ lib, pkgs, config, ... }:

{

    imports = [
        ./id.nix
    ];

    boot.initrd = {
        systemd.enable = true;
    };

    boot.loader.grub.enable = lib.mkDefault false;

    boot.kernel.sysctl = {
        "kernel.unprivileged_bpf_disabled" = 1;
        "dev.tty.ldisc_autoload" = 0;
        "vm.max_map_count" = 2147483642;
        "kernel.sysrq" = 1;
        "net.ipv4.ip_unprivileged_port_start" = 80;
        "vm.overcommit_memory" = 1;
    };

    boot.kernelParams = [
        "efi_pstore.pstore_disable=1"
        # "ia32_emulation=0"
        "init_on_alloc=1"
        "vsyscall=none"
        "intel_iommu=on"
        "amd_iommu=on"
        "transparent_hugepage=always"
        "nmi_watchdog=0"
        # use zram swap
        "zswap.enabled=0"
    ];

    boot.blacklistedKernelModules = [
        "sp5100_tco" "iTCO_wdt"
    ];

    boot.tmp = {
        # useTmpfs = true;
        tmpfsSize = "100%";
        useZram = true;
        zramSettings.zram-size = "ram";
        zramSettings.fs-type = "xfs";
    };

    boot = {
        bcache.enable = false;
        enableContainers = false;
    };

    boot.kernel.sysfs = {
        # ref: https://github.com/CachyOS/CachyOS-Settings/
        kernel.mm.transparent_hugepage = {
            enabled = "always";
            defrag = "defer";
            shmem_enabled = "within_size";
            khugepaged.max_ptes_none = "400";
        };
    };

    boot.initrd.includeDefaultModules = false;

    boot.initrd.availableKernelModules = [
        "ahci"
        "nvme"
        "uhci_hcd"
        "ehci_hcd"
        "ehci_pci"
        "ohci_hcd"
        "ohci_pci"
        "xhci_hcd"
        "xhci_pci"
        "usbhid"
        "hid_generic"
        "atkbd"
    ];

    boot.initrd.kernelModules = [
        "dm_mod"
    ];
}
