{ dots, pkgs, ... }:

{

    packages = [ pkgs.mpv ];

    xdg_config."mpv/mpv.conf".src = dots.get "mpv/mpv.conf";
    xdg_config."mpv/input.conf".src = dots.get "mpv/input.conf";

}
