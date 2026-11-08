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
        sops.age.keyFile = "/var/lib/age.txt";
    }

    (for [ machines.umi ] {
        sops.defaultSopsFile = ./umi/main.yml;
    })

    (for [ machines.uk-01 ] {
        sops.defaultSopsFile = ./uk-01/main.yml;
    })

    (for (with machines; [ umi uk-01 ]) {
        sops.secrets = {
            ssh_ed25519_key = { };
            ssh_ed25519_pub = { };
        };
    })

    (for [ machines.umi ] {
        sops.secrets = {
            "key--ssh--teapot".owner = teapot;
            "token--github--me".owner = teapot;
            "conf--ssh" = {
                sopsFile = ./umi/conf--ssh.sops;
                owner = teapot;
                format = "binary";
            };
            "rclone.conf" = {
                sopsFile = ./umi/rclone.sops;
                format = "binary";
                # insecure, but only on machiens in the lan
                mode = "0644";
            };
        };
        environment.etc."rclone.conf".source =
            config.sops.secrets."rclone.conf".path;
    })

    (for (with machines; [ umi uk-01 ]) {
        sops.secrets."token--cloudflare" = {
            sopsFile = ./shared/token--cloudflare.sops.yml;
            key = "api_token";
        };
    })

]
