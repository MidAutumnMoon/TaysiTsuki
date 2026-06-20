# lny module — installs swayimg; symlinks repo home/swayimg/init.lua -> $XDG_CONFIG_HOME/swayimg/init.lua
{ dots, pkgs, ... }:

{

    packages = with pkgs; [
        swayimg
    ];

    xdg_config."swayimg/init.lua".src = dots.get "swayimg/init.lua";

}
