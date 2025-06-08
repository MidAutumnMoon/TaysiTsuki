{ config, nixosConfig, ... }:

let

    inherit ( config.lib.file )
        mkOutOfStoreSymlink
    ;

    inherit ( config.sops )
        secrets
    ;

in {

    sops.secrets = {
        "ssh_config" = {
            format = "binary";
            sopsFile = ./ssh_config.sops;
        };
        "privkey_teapot".sopsFile = ./private_key.sops.yml;
    };

    home.file = {
        ".ssh/config".source = mkOutOfStoreSymlink secrets."ssh_config".path;
        ".ssh/id_teapot".source = mkOutOfStoreSymlink secrets."privkey_teapot".path;
        ".ssh/id_teapot.pub".text = nixosConfig.lore.pubkeys.teapot;
    };

}
