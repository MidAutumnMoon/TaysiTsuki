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
        ];
        tmp.useTmpfs = true;
        tmp.tmpfsSize = "100%";
        bcache.enable = false;
    };

    i18n.defaultLocale = "en_US.UTF-8";
    time.timeZone = lib.mkDefault "Asia/Shanghai";

    programs = {
        command-not-found.enable = false;
    };

    environment.defaultPackages = lib.mkDefault [];

    environment.systemPackages = with pkgs; [
        fd
        ripgrep
        file
        htop
        screen
        mtr
        rsync
        strace
    ];

    services = {
        dbus.implementation = "broker";
        vnstat.enable = true;
        userborn.enable = true;
    };

    # Don't want to manually update it once a while.
    system.stateVersion = lib.trivial.release;

}
