{ config, ... }:

let

    inherit ( config.lib.file )
        mkOutOfStoreSymlink
    ;

    inherit ( config.sops )
        secrets
    ;

in {

    sops.secrets = {
        "mkcert_rootca".sopsFile = ./mkcert.sops.yml;
        "mkcert_rootca_key".sopsFile = ./mkcert.sops.yml;
    };

    xdg.dataFile = {
        "mkcert/rootCA.pem".source =
            mkOutOfStoreSymlink secrets."mkcert_rootca".path;

        "mkcert/rootCA-key.pem".source =
            mkOutOfStoreSymlink secrets."mkcert_rootca_key".path;
    };

}
