{ pkgs, dots, ... }:

let

    _7zzWith7zAlias = pkgs.symlinkJoin {
        name = "7zz-with-7z-alias";
        paths = [ pkgs._7zz ];
        postBuild = ''
            ln -s $out/bin/7zz $out/bin/7z
        '';
    };

in

{

    packages = with pkgs; [
        _7zzWith7zAlias
        par2cmdline-turbo
        jq
    ];

    home.".local/bin".src = dots.get "bin";

}
