{

    sops.secrets = {
        "cert--home_lan--cert".sopsFile = ./cert--home_lan.sops.yml;
        "cert--home_lan--key".sopsFile = ./cert--home_lan.sops.yml;
        "conf--rclone".sopsFile = ./conf--rclone.sops.yml;

        "token--cloudflare" = {
            sopsFile = ./token--cloudflare.sops.yml;
            key = "api_token";
        };

    };

}
