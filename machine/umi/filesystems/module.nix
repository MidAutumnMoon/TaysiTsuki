{ config, ... }:

let

    btrfsOption = subvol: [
        "subvol=${subvol}"
        "compress-force=zstd"
        "noatime"
    ];

    luksDeviceName = "minato";

    luksDevice = "/dev/mapper/${luksDeviceName}";

in

{

    zramSwap = {
        enable = true;
        memoryPercent = 100;
    };

    boot.initrd.luks.devices = {
        "${luksDeviceName}" = {
            device = "/dev/disk/by-uuid/95591c3a-d3ed-4870-947b-15339527c596";
            allowDiscards = true;
            bypassWorkqueues = true;
            crypttabExtraOpts = [ "fido2-device=auto" ];
        };
    };

    fileSystems = {
        "/" = {
            device = "none";
            fsType = "tmpfs";
            options = [ "defaults,mode=755,nosuid,nodev,size=100%" ];
        };
        # scratchpad
        "/home/teapot/z" = {
            device = "none";
            fsType = "tmpfs";
            options = [
                "defaults,mode=777,size=100%,noatime"
                "noswap"
                "huge=always"
            ];
        };
        "/boot" = {
            device = "/dev/disk/by-uuid/3603-DD8C";
            fsType = "vfat";
            options = [ "fmask=0022" "dmask=0022" ];
        };
        "/nix" = {
            device = luksDevice;
            fsType = "btrfs";
            options = btrfsOption "nix";
        };
        "/var/lib" = {
            device = luksDevice;
            fsType = "btrfs";
            options = btrfsOption "var-lib";
        };
        "/var/lib/.snapshots" = {
            device = luksDevice;
            fsType = "btrfs";
            options = btrfsOption "var-lib-snapshot";
        };
        "/var/log" = {
            device = luksDevice;
            fsType = "btrfs";
            options = btrfsOption "var-log";
        };
        "/persist" = {
            device = luksDevice;
            fsType = "btrfs";
            options = btrfsOption "persist";
            neededForBoot = true;
        };
        "/persist/.snapshots" = {
            device = luksDevice;
            fsType = "btrfs";
            options = btrfsOption "persist-snapshot";
        };
        "/home" = {
            device = luksDevice;
            fsType = "btrfs";
            options = btrfsOption "home";
        };
        "/home/.snapshots" = {
            device = luksDevice;
            fsType = "btrfs";
            options = btrfsOption "home-snapshot";
        };
        "/srv" = {
            device = luksDevice;
            fsType = "btrfs";
            options = btrfsOption "srv";
        };
    };

    services = {
        btrfs.autoScrub.enable = true;
    };

    services.udev.extraRules = ''
        ACTION=="add|change", KERNEL=="nvme[0-9]*n[0-9]*", ATTR{queue/scheduler}="none"
    '';

}
