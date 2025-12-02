{
    sops.secrets = {
        "token--cloudflare" = {
            sopsFile = ./token--cloudflare.sops.yml;
            key = "api_token";
        };
    };
}
