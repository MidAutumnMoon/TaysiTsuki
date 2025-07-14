{ dots, pkgs, ... }:

{

    packages = [ pkgs.mpv ];

    xdg_config."mpv".src = dots.get "mpv";

}
