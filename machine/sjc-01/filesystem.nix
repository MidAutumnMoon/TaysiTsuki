{ lib, ... }:

{

    disko.devices.disk."main" = {
        type = "disk";
        device = lib.mkDefault "/dev/vda";
        content.type = "gpt";
        content.partitions = {
            boot = {
                size = "1M";
                type = "EF02";
            };
            mainfs = {
                size = "100%";
                content = {
                    type = "btrfs";
                    mountpoint = "/";
                    mountOptions = [
                        "defaults" "noatime"
                        "compress-force=zstd:3"
                    ];
                };
            };
        };
    };

    zramSwap = {
        enable = true;
        memoryPercent = 100;
    };

}
