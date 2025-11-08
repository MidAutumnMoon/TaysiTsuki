{ config, ... }:

let

    btrfsOption = subvol: [
        "subvol=${subvol}"
        "compress-force=zstd"
        "noatime"
    ];

    sambaOption = [
        "x-systemd.automount"
        "x-systemd.mount-timeout=10s"
        "x-systemd.idle-timeout=1hour"
        "_netdev"
        "noauto"
        "noatime"
        "noserverino"
        "user"
        "users"
        "vers=3.1.1"
        "nofail"
        "iocharset=utf8"
        "echo_interval=30"
        "uid=${toString config.users.users.teapot.uid}"
        "gid=${toString config.users.groups.users.gid}"
    ];

    luksDevice = "/dev/mapper/rin";

in

{

    zramSwap = {
        enable = true;
        memoryPercent = 100;
    };

    boot.initrd.luks.devices = {
        "rin" = {
            device = "/dev/disk/by-uuid/b0fb796a-6982-4c87-b261-80159d03946d";
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
        "/mnt/z" = {
            device = "none";
            fsType = "tmpfs";
            options = [
                "defaults,mode=777,size=100%,noatime"
                "noswap"
                "huge=always"
            ];
        };
        "/boot" = {
            device = "/dev/disk/by-uuid/B6AC-C76F";
            fsType = "vfat";
            options = [ "fmask=0022" "dmask=0022" ];
        };
        "/nix" = {
            device = luksDevice;
            fsType = "btrfs";
            options = btrfsOption "nix";
        };
        "/var" = {
            device = luksDevice;
            fsType = "btrfs";
            options = btrfsOption "var";
        };
        "/persist" = {
            device = luksDevice;
            fsType = "btrfs";
            options = btrfsOption "persist";
            neededForBoot = true;
        };
        "/home" = {
            device = luksDevice;
            fsType = "btrfs";
            options = btrfsOption "home";
        };
        "/mnt/pool" = {
            # TODO: no hardcode hostname and path
            device = "//phia.local/pool";
            fsType = "cifs";
            options = sambaOption ++ [];
        };
        "/mnt/torrent" = {
            # TODO: no hardcode hostname and path
            device = "//phia.local/torrent";
            fsType = "cifs";
            options = sambaOption ++ [];
        };
    };

    services = {
        btrfs.autoScrub.enable = true;
    };

}
