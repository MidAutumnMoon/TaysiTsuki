{ lib, ... }:

{

    time.timeZone = lib.mkDefault "Asia/Shanghai";

    i18n.defaultLocale = "en_US.UTF-8";

    system = {
        etc.overlay.enable = true;
        tools.nixos-generate-config.enable = false;
        # forbiddenDependenciesRegexes = [ "perl" ];
    };

    # Don't want to manually update it once a while.
    system.stateVersion = lib.trivial.release;

    systemd.extraConfig = ''
        DefaultTimeoutStopSec = 20s
    '';

}
