{ pkgs, lib, ... }:

let

    disableZswap =
        pkgs.writeShellScript "disable-zswap"
        ''echo N > /sys/module/zswap/parameters/enabled'';

in

{

    # Some rules are taken from CachyOS/CachyOS-Settings
    services.udev.extraRules = ''
        ACTION=="change", KERNEL=="zram0", ATTR{initstate}=="1", \
            SYSCTL{vm.swappiness}="150", RUN+="${disableZswap}"

        KERNEL=="rtc0", GROUP="audio"
        KERNEL=="hpet", GROUP="audio"
    '';

}
