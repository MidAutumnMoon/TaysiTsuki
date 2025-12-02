{ lib, ... }:

{

    time.timeZone = lib.mkDefault "Asia/Taipei";

    i18n.defaultLocale = "en_US.UTF-8";

    system = {
        etc.overlay.enable = true;
        etc.overlay.mutable = false;
        tools.nixos-generate-config.enable = false;
        # forbiddenDependenciesRegexes = [ "perl" ];
        disableInstallerTools = true;
        nixos-init.enable = true;
    };

    # Don't want to manually update it once a while.
    system.stateVersion = lib.trivial.release;

}
