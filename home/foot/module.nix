# lny module — installs foot; symlinks repo home/foot/foot.ini -> $XDG_CONFIG_HOME/foot/foot.ini
{ lib, dots, pkgs, ... }:

{

    packages = with pkgs; [
        foot
    ];

    xdg_config."foot/foot.ini".src = dots.get "foot/foot.ini";

}
