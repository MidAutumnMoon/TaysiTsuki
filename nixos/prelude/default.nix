{ lib, pkgs, ... }:

{

    boot = {
        kernelPackages = pkgs.linuxPackages_latest;
        kernel.sysctl = {
            "kernel.unprivileged_bpf_disabled" = 1;
            "dev.tty.ldisc_autoload" = 0;
            "vm.max_map_count" = 2147483642;
            "kernel.sysrq" = 1;
            "net.ipv4.ip_unprivileged_port_start" = 80;
        };
        kernelParams = [
            "efi_pstore.pstore_disable=1"
            "ia32_emulation=0"
            "init_on_alloc=1"
            "vsyscall=none"
            "intel_iommu=on"
            "amd_iommu=on"
        ];
        tmp.useTmpfs = true;
        tmp.tmpfsSize = "100%";
        bcache.enable = false;
        enableContainers = false;
    };

    boot.initrd = {
        systemd.enable = true;
    };

    boot.loader.grub.enable = lib.mkDefault false;

    system = {
        etc.overlay.enable = true;
        tools.nixos-generate-config.enable = false;
        # forbiddenDependenciesRegexes = [ "perl" ];
        rebuild.enableNg = true;
    };

    i18n.defaultLocale = "en_US.UTF-8";
    time.timeZone = lib.mkDefault "Asia/Shanghai";

    programs = {
        command-not-found.enable = false;
    };

    services = {
        dbus.implementation = "broker";
        vnstat.enable = true;
        userborn.enable = true;
    };

    environment = {
        defaultPackages = lib.mkDefault [];
        systemPackages = with pkgs; [
            fd
            ripgrep
            file
            btop
            screen
            mtr
            rsync
            strace
        ];
    };

    # Don't want to manually update it once a while.
    system.stateVersion = lib.trivial.release;

}
