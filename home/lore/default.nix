{ lib, config, ... }:

let

    inherit ( lib )
        types
    ;

in {

    options.lore = {
        tsukiObservatory = lib.mkOption {
            type = types.path;
            readOnly = true;
            default = "${config.home.homeDirectory}/TaysiTsuki";
        };
    };

}
