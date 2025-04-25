{ pkgs, config, ... }:

let

    poolMountpoint =
        config.fileSystems."/srv/pool".mountPoint;

in

{

    services.samba = {
        enable = true;
        openFirewall = true;
    };

    services.samba.settings = {
        "global" = {
            "workgroup" = "WORKGROUP";
            "server string" = "Teapot Homelab";
            "security" = "user";
            "use sendfile" = "yes";
            "map to guest" = "bad user";
            "guest account" = "nobody";
            "server min protocol" = "SMB3_11";
            "logging" = "systemd";
            "getwd cache" = "yes";
            "socket options" = "IPTOS_LOWDELAY TCP_NODELAY";
            "deadtime" = "120";
            "min receivefile size" = "16384";
            "case sensitive" = "yes";
        };
        "pool" = {
            "path" = poolMountpoint;
            "browseable" = "yes";
            "read only" = "no";
            "guest ok" = "yes";
            "create mask" = "0644";
            "directory mask" = "0755";
            "writable" = "yes";
            "force user" = "fileshare";
            "force group" = "users";
            "vfs objects" = "recycle";
            "recycle:repository" = ".recycle";
            "recycle:keeptree" = "yes";
            "recycle:versions" = "yes";
            "recycle:exclude" = "*.tmp *.temp ~$*";
            "recycle:touch" = "yes";
        };
    };

    # Avoid using nobody
    users.users."fileshare" = {
        isNormalUser = true;
    };

    systemd.tmpfiles.rules = [
        "d ${poolMountpoint} 0755 fileshare users - -"
    ];

    services.samba-wsdd = {
        enable = true;
        openFirewall = true;
    };

    services.avahi = {
        enable = true;
        openFirewall = true;
        publish.enable = true;
        publish.userServices = true;
        nssmdns4 = true;
        nssmdns6 = true;
    };

    systemd.services."empty-samba-recycle-bin" = {
        description = "Empty ${poolMountpoint} recycle bin";
        script = /* bash */ ''
            echo "Start empty recycle bin"
            RecycleBin="${poolMountpoint}/.recycle"
            if [[ -d "$RecycleBin" ]]; then
                rm -rvf "$RecycleBin"/*
            fi
            echo "Finish empty recycle bin"
        '';
        startAt = "daily";
    };

    systemd.timers."empty-samba-recycle-bin" = {
        timerConfig.Persistent = true;
    };

}
