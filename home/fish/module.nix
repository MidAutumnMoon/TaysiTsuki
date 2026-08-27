# lny module
# 1. installs fish
# 2. symlinks repo home/fish/functions -> $XDG_CONFIG_HOME/fish/functions
# 3. symlinks repo home/fish/conf.d -> $XDG_CONFIG_HOME/fish/conf.d
{ dots, pkgs, ... }:

{

    packages = [ pkgs.fish ];

    xdg_config."fish/functions".src = dots.get "fish/functions";
    xdg_config."fish/conf.d".src = dots.get "fish/conf.d";

}
