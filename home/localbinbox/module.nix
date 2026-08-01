# lny module — installs 7zz/jq/localbinbox; symlinks repo home/localbinbox/scripts -> $HOME/.local/bin
{ pkgs, dots, ... }:

let

    _7zzWith7zAlias = pkgs.symlinkJoin {
        name = "7zz-with-7z-alias";
        paths = [ pkgs._7zip-zstd ];
        postBuild = ''
            ln -s $out/bin/7zz $out/bin/7z
        '';
    };

    localbinbox = pkgs.callPackage ./. {};

in

{

    packages = with pkgs; [
        _7zzWith7zAlias
        jq
        localbinbox
    ];

    home.".local/bin".src = dots.get "localbinbox/scripts";

}
