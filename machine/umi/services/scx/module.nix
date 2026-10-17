{ pkgs, ... }:

let

    scheduler = "scx_flash";

    rustscheds = pkgs.scx.rustscheds;

    trimmed = pkgs.runCommandLocal "scx-rustscheds-${scheduler}" {
        passthru.schedulers = [ scheduler ];
    } ''
        install -Dm755 ${rustscheds}/bin/${scheduler} $out/bin/${scheduler}
    '';

in {

    services.scx = {
        enable = true;
        inherit scheduler;
        package = trimmed;
    };

}
