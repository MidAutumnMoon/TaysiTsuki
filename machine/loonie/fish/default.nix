{ lib, config, ... }:

{

    imports = [
        ./parallel-compgen.nix
    ];

    assertions = [ {
        assertion = !config.programs.fish.enable;
        message = ''
            The majority of fish module's functionality is
            reimplemented in a cleaner manner, the upstream module
            is not only useless but also causes conflicts.
        '';
    } ];

    environment.pathsToLink = [
        "/share/fish/vendor_conf.d"
        "/share/fish/vendor_completions.d"
        "/share/fish/vendor_functions.d"
    ];

}
