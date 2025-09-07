# Example to create a bios compatible gpt partition
{ lib, ... }:

{
    disko.devices.disk."main" = {
        type = "disk";
        device = lib.mkDefault "/dev/vda";
        content.type = "gpt";
        content.partitions = {
            boot = {
                name = "boot";
                size = "1M";
                type = "EF02";
            };
            root = {
                name = "root";
                size = "100%";
                content = {
                    type = "btrfs";
                    mountpoint = "/";
                    mountOptions = [
                        "defaults" "noatime" "compress-force=zstd:3"
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
