{ config, lib, ... }:

let

    onlyMachine = name:
        lib.mkIf ( config.networking.hostName == name );

in

lib.mkMerge [

    {
        sops.defaultSopsFile = ./default.sops.nix;
    }

    ( onlyMachine config.lore.machines.ren.hostname (
        let teapot = config.users.users.teapot.name; in
        {
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
        }
    ) )

]
