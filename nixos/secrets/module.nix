{

    sops.secrets = {

        "conf--rclone".sopsFile = ./conf--rclone.sops.yml;

        "token--cloudflare" = {
            sopsFile = ./token--cloudflare.sops.yml;
            key = "api_token";
        };

    };

}
