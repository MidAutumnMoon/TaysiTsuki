{}
# { config, ... }:

# let

#     inherit ( config ) lore;

#     poolMnt = config.fileSystems."/mnt/pool".mountPoint;

# in

# {

#     services.navidrome = {
#         enable = false;
#         openFirewall = false;
#         settings = {
#             # seems reasonable
#             EnableInsightsCollector = true;
#             Address = "127.0.0.1";
#             Port = lore.ports.navidrome;
#             MusicFolder = "${poolMnt}/Music";
#             # default but without "albumartistid"
#             PID.Album = "musicbrainz_albumid|album,albumversion,releasedate";
#         };
#     };

#     systemd.services.navidrome = {
#         unitConfig.WantsMountsFor = [ poolMnt ];
#         # Bind the whole samba share to use multiple libraries
#         serviceConfig.BindReadOnlyPaths = [ poolMnt ];
#     };

#     services.caddy.virtualHosts."im_418".extraConfig =
#         ''
#             @music host ${lore.apps.homelab.navidrome.fqdn}
#             handle @music {
#                 reverse_proxy http://127.0.0.1:${toString lore.ports.navidrome}
#             }
#         '';

# }
