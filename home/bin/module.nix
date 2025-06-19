{ pkgs, dots, ... }:

{

    packages = with pkgs; [
        _7zz
        par2cmdline-turbo
        jq
    ];

    home.".local/bin".src = dots.get "bin";

}
