{ config, lib, ... }:

let

    slskdCfg = config.services.slskd;

    baseDir = "/srv/slskd";
    incompleteDir = "${baseDir}/incomplete";
    downloadsDir = "${baseDir}/downloads";
    sharesDir = "${baseDir}/shares";

in {
    #
    # systemd.tmpfiles.settings."10-slskd" = lib.forEach
    #     [ baseDir incompleteDir downloadsDir sharesDir ]
    #     (dir: {
    #         ${dir}.d = {
    #             inherit (slskdCfg) user group;
    #             mode = "755";
    #         };
    #     })
    #     |> lib.mergeAttrsList;
    #
    # services.slskd = {
    #     enable = false;
    #     openFirewall = true;
    #     environmentFile = config.sops.secrets."slskd_cred".path;
    #     settings = {
    #         directories = {
    #             incomplete = incompleteDir;
    #             downloads = downloadsDir;
    #         };
    #         soulseek.listen_port = config.lore.ports.slskd;
    #         web = {
    #             port = config.lore.ports.slskdWebui;
    #             url_base = "/";
    #             https.disabled = true;
    #         };
    #         global = {
    #             upload = { slots = 5; };
    #             download = { slots = 5; };
    #         };
    #         shares = {
    #             directories = [ downloadsDir ];
    #         };
    #     };
    #     domain = null;
    # };
    #
    # services.caddy.virtualHosts."im_418".extraConfig = ''
    #     @slskdwebui {
    #         host ${config.lore.apps.tailnet.slskd_dashboard.fqdn}
    #         client_ip private_ranges
    #     }
    #     handle @slskdwebui {
    #         reverse_proxy http://localhost:${toString
    #             slskdCfg.settings.web.port
    #         }
    #     }
    # '';
    #
    # sops.secrets.slskd_cred = {
    #     format = "binary";
    #     sopsFile = ./slskd;
    # };
    #
    # systemd.services.slskd = {
    #     serviceConfig = {
    #         # less secure, but meh
    #         ReadOnlyPaths = lib.mkForce [];
    #     };
    # };

}
