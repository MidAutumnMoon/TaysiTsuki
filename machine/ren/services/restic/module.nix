{ lib, config, pkgs, ... }:

let

    inherit (config.networking) hostName;

    # Selective backup: most personal data lives on NAS,
    # only irreplaceable bits of home are backed up.
    # Each entry:
    #   name     - snapper config name (key into services.snapper.configs)
    #   user     - optional path prefix (e.g. "teapot") prepended to subpaths
    #   subpaths - paths within the snapshot to back up;
    #              empty/absent = whole snapshot
    volsToBackup = [
        {
            name = "var";
            subpaths = [ "lib" ];
        }
        { name = "persist"; }
        {
            name = "home";
            user = "teapot";
            subpaths = [
                ".mozilla"
                # add more paths as needed, e.g. ".var/app/<app-id>", ".config/<app>"
            ];
        }
    ];

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

    latestSnapshotOf = entry:
        let
            vol = config.services.snapper.configs.${entry.name}.SUBVOLUME;
            user = entry.user or null;
            prefix = lib.optionalString (user != null) "${user}/";
            subpaths = entry.subpaths or [];
            # empty subpaths => whole snapshot
            targets =
                if subpaths == []
                then [ "" ]
                else map (sp: "${prefix}${sp}") subpaths;
            printTarget = target:
                if target == ""
                then ''printf "%s\n" "$LATEST_SNAPSHOT"''
                else ''printf "%s\n" "$LATEST_SNAPSHOT/${target}"'';
        in ''
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
            if [ ! -d "$LATEST_SNAPSHOT" ]; then
                echo "[BUG] $LATEST_SNAPSHOT does not exist"
                exit 1
            fi
            ${lib.concatStringsSep "\n" (map printTarget targets)}
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
            map latestSnapshotOf volsToBackup
            |> lib.concatStringsSep "\n";

        backupPrepareCommand =
            map (entry: ''
                echo "Take a snapshot of ${entry.name} before backup"
                ${lib.getExe pkgs.snapper} -c ${entry.name} \
                    create \
                    --description "Snapshot before backup" \
                    -c number
            '') volsToBackup
            |> lib.concatStringsSep "\n";
    };
}
