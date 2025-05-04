{ lib, firefox }:

lib.onceride firefox

( _: {

    extraPolicies =
        import ./policies.nix;

    extraPrefs =
        builtins.readFile ./autoconfig.js;

} )

( oldAttrs: {

    # 1) fake timezone to enhance privacy protection

    buildCommand = oldAttrs.buildCommand + ''
        mv $out/bin/{firefox,.firefox-old}

        makeWrapper $out/bin/{.firefox-old,firefox} \
            --set TZ "Asia/Tokyo"
    '';
} )
