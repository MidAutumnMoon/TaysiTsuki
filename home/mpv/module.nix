# lny module — installs mpv; symlinks repo home/mpv (dir) -> $XDG_CONFIG_HOME/mpv
{ dots, pkgs, ... }:

{

    packages = [ pkgs.mpv ];

    xdg_config."mpv".src = dots.get "mpv";

}
