# lny module — installs 7zz/jq/localbinbox; symlinks repo home/localbinbox/scripts -> $HOME/.local/bin
{ pkgs, dots, ... }:

let
    localbinbox = pkgs.callPackage ./. {};
in

{

    packages = with pkgs; [
        _7zip-zstd
        jq
        localbinbox
    ];

    home.".local/bin".src = dots.get "localbinbox/scripts";

}
