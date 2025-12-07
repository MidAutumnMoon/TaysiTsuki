{ config, lib, ... }:

let

    for = machines:
        map (m: m.hostname) machines
        |> (ms: lib.mkIf (
            lib.elem config.networking.hostName ms
        ));

    inherit (config.lore)
        machines
    ;

    teapot = config.users.users.teapot.name;

in

lib.mkMerge [

    {
        sops.defaultSopsFile = ./default.sops.nix;
    }

    (for [ machines.ren ] {
        sops.secrets = {
            "key--ssh--teapot" = {
                sopsFile = ./ren/key--ssh--teapot.sops.yml;
                owner = teapot;
            };
            "conf--ssh" = {
                sopsFile = ./ren/conf--ssh.sops;
                owner = teapot;
                format = "binary";
            };
            "token--github--me" = {
                sopsFile = ./ren/token--github.sops.yml;
                owner = teapot;
            };
        };
    })

    (for (with machines; [ ren phia ]) {
        sops.secrets."rclone.conf" = {
            sopsFile = ./mixed/rclone;
            format = "binary";
            # insecure, but only on machiens in the lan
            mode = "0644";
        };
        environment.etc."rclone.conf".source =
            config.sops.secrets."rclone.conf".path;
    })

]
