{ lib, pkgs, config, ... }:

let

    selfCfg = config.services.avahi2dns;
    avahiCfg = config.services.avahi;

    avahiService =
        config.systemd.services.avahi-daemon.name;

in

{
    options.services.avahi2dns = {
        enable = lib.mkEnableOption "avahi2dns service";
        port = lib.mkOption {
            type = lib.types.port;
            default = config.lore.ports.avahi2dns;
            description = "avahi2dns DNS server listen port";
        };
    };

    config = lib.mkIf (avahiCfg.enable && selfCfg.enable) {
        systemd.services."avahi2dns" = {
            requires = [ avahiService ];
            after = [ avahiService ];
            wantedBy = [ "multi-user.target" ];
            script = ''
                exec ${lib.getExe pkgs.tsuki.avahi2dns} \
                    --port ${toString selfCfg.port} \
                    --timeout 8s
            '';
            useHardening = true;
        };
    };
}
