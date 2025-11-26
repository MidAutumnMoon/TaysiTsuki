{ lib, pkgs, config, ... }:

{

    boot.initrd = {
        systemd.enable = true;
    };

    boot.loader.grub.enable = lib.mkDefault false;

    boot.kernelPackages = pkgs.linuxPackages_latest;

    boot.kernel.sysctl = {
        "kernel.unprivileged_bpf_disabled" = 1;
        "dev.tty.ldisc_autoload" = 0;
        "vm.max_map_count" = 2147483642;
        "kernel.sysrq" = 1;
        "net.ipv4.ip_unprivileged_port_start" = 80;
    };

    boot.kernelParams = [
        "efi_pstore.pstore_disable=1"
        "ia32_emulation=0"
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

    boot.supportedFilesystems =
        let
            zramCfg = config.boot.tmp.zramSettings;
        in {
            ${zramCfg.fs-type} = true;
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

}
