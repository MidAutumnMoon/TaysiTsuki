{ config, pkgs, ... }:

let

    poolMpt =
        config.fileSystems."/srv/pool".mountPoint;

    torrentMpt =
        config.fileSystems."/srv/torrent".mountPoint;

    fileshareUser =
        config.users.users."fileshare".name;

in

{

    services.samba = {
        enable = true;
        openFirewall = true;
    };

    services.samba.settings = let
        commonShareOpt = {
            "browseable" = "yes";
            "read only" = "no";
            "guest ok" = "yes";
            "create mask" = "0644";
            "directory mask" = "0755";
            "writable" = "yes";
            "force user" = fileshareUser;
            "force group" = "users";
            "vfs objects" = "recycle";
            "recycle:repository" = ".recycle";
            "recycle:keeptree" = "yes";
            "recycle:versions" = "yes";
            "recycle:exclude" = "*.tmp *.temp ~$*";
            "recycle:touch" = "yes";
        };
    in {
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
        "pool" = commonShareOpt // {
            "path" = poolMpt;
        };
        "torrent" = commonShareOpt // {
            "path" = torrentMpt;
        };
    };

    services.samba-wsdd = {
        enable = true;
        openFirewall = true;
    };

    services.avahi = {
        enable = true;
        openFirewall = true;
        publish.enable = true;
        publish.userServices = true;
        publish.domain = true;
        nssmdns4 = true;
        nssmdns6 = true;
    };

    systemd.services."empty-samba-recycle-bin" = {
        description = "Empty ${poolMpt} recycle bin";
        script = /* bash */ ''
            declare -r RecycleBin="${poolMpt}/.recycle"
            declare -r EmptyDir="$( mktemp -d )"
            echo "Start empty recycle bin"
            if [[ -d "$RecycleBin" ]]; then
                # N.B. / after dirs
                rsync -rvP --delete "$EmptyDir/" "$RecycleBin/"
            fi
            echo "Finish empty recycle bin"
        '';
        startAt = "daily";
        path = [ pkgs.rsync ];
    };

    systemd.timers."empty-samba-recycle-bin" = {
        timerConfig.Persistent = true;
    };

}
