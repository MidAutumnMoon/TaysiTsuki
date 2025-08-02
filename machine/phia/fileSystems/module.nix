{

    fileSystems = {
        "/" = {
            device = "none";
            fsType = "tmpfs";
            options = [ "defaults" "mode=755" "nosuid" "nodev" "size=8G" ];
        };
        "/boot" = {
            device = "/dev/disk/by-uuid/3C67-B074";
            fsType = "vfat";
            options = [ "fmask=0022" "dmask=0022" ];
        };
        "/nix" = {
            device = "phia/nix";
            fsType = "zfs";
        };
        "/var" = {
            device = "phia/var";
            fsType = "zfs";
        };
        "/persist" = {
            device = "phia/persist";
            fsType = "zfs";
            neededForBoot = true;
        };
        "/root" = {
            device = "phia/root";
            fsType = "zfs";
        };
        "/home" = {
            device = "phia/home";
            fsType = "zfs";
        };
        "/srv" = {
            device = "phia/srv";
            fsType = "zfs";
        };
        "/srv/pool" = {
            device = "phia/srv/pool";
            fsType = "zfs";
        };
        "/srv/torrent" = {
            device = "phia/srv/torrent";
            fsType = "zfs";
        };
    };

    zramSwap.enable = true;

    services.zfs = {
        autoScrub.enable = true;
        trim.enable = true;
    };

}
