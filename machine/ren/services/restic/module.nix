{ lib, config, pkgs, ... }:

let

    inherit (config.networking) hostName;

    # Almost all personal data is stored on NAS,
    # so backup of home is unnecessary.
    volsToBackup = [ "var" "persist" ];

    # TODO: avoid hardcoding :/
    # Ideally also dedup it from phia/maintainace
    rcloneRemote = "Box";
    backupSubdir = "Backup";

    exclude = [
        "flatpak"
        "private"
        "sddm"
        "cache" "_cache"
        "systemd" "tmp"
    ];

    latestSnapshotOf = vol: ''
        SNAPSHOTS="${vol}/.snapshots"
        if [ ! -d "$SNAPSHOTS" ]; then
            echo "Snapshot dir $SNAPSHOTS does not exist"
            exit 1
        fi
        LATEST=$(
            ls -1 "$SNAPSHOTS" \
            | grep -E '^[0-9]+$' \
            | sort -n | tail -n 1 )
        if [ ! -n "$LATEST" ]; then
            echo "[BUG] No snapshots"
            exit 1
        fi
        LATEST_SNAPSHOT="$SNAPSHOTS/$LATEST/snapshot"
        if [ -d "$LATEST_SNAPSHOT" ]; then
            # TODO: avoid "/var/lib" hack
            if [ "${vol}" = "/var" ]; then
                printf "%s\n" "$LATEST_SNAPSHOT/lib"
            else
                printf "%s\n" "$LATEST_SNAPSHOT"
            fi
        else
            echo "[BUG] $LATEST_SNAPSHOT does not exist"
            exit 1
        fi
    '';

in {
    sops.secrets."backup-restic-passwd" ={
        sopsFile = ./restic-passwd.yml;
    };

    services.restic.backups."system-backup" = {
        initialize = true;

        repository =
            "rclone:${rcloneRemote}:${backupSubdir}/${hostName}";
        passwordFile =
            config.sops.secrets."backup-restic-passwd".path;
        rcloneConfigFile =
            config.sops.secrets."rclone.conf".path;

        inherit exclude;

        timerConfig = {
            OnCalendar = "hourly";
            Persistent = true;
        };

        extraBackupArgs = [
            "--pack-size=128"
            "--tag=snapshot"
            "--exclude-caches"
            "--verbose=2"
        ];

        # Hourly snapshots of about 5 days
        pruneOpts = [
            # f restic
            "--group-by=tags"
            "--tag=snapshot"
            "--keep-hourly=120"
        ];

        dynamicFilesFrom =
            map (vol: config.services.snapper.configs.${vol}.SUBVOLUME)
                volsToBackup
            |> map latestSnapshotOf
            |> lib.concatStringsSep "\n";

        backupPrepareCommand =
            map (vol: ''
                echo "Take a snapshot of ${vol} before backup"
                ${lib.getExe pkgs.snapper} -c ${vol} \
                    create \
                    --description "Snapshot before backup" \
                    -c number
            '') volsToBackup
            |> lib.concatStringsSep "\n";
    };
}
