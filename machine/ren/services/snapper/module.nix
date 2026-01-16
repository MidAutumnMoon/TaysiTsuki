{ lib, config, ... }:

let

    mntOf = name: config.fileSystems.${name}.mountPoint;

    snapshotVols = {
        home = {
            SUBVOLUME = mntOf "/home";
        };
        var = {
            SUBVOLUME = mntOf "/var";
        };
        persist = {
            SUBVOLUME = mntOf "/persist";
        };
    };

    snapperCommon = {
        TIMELINE_CLEANUP = true;
        TIMELINE_CREATE = true;
        # hourly snapshot of 7 days
        TIMELINE_LIMIT_HOURLY = "180";
        TIMELINE_LIMIT_DAILY = "0";
        TIMELINE_LIMIT_WEEKLY = "0";
        TIMELINE_LIMIT_MONTHLY = "0";
        TIMELINE_LIMIT_QUARTERLY = "0";
        TIMELINE_LIMIT_YEARLY = "0";
        NUMBER_LIMIT = "0";
        NUMBER_CLEANUP = "0";
    };

in lib.mkMerge [
    {
        services.snapper = {
            snapshotRootOnBoot = false;
            cleanupInterval = "3h";
            persistentTimer = true;
        };
    }
    {
        services.snapper.configs =
            lib.flip lib.mapAttrs snapshotVols
            (name: config: snapperCommon // config);
    }
]
