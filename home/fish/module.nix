# lny module — installs fish; symlinks repo home/fish (dir) -> $XDG_CONFIG_HOME/fish/functions
# and repo home/fish/conf.d/__moonstep.fish -> $XDG_CONFIG_HOME/fish/conf.d/__moonstep.fish
{ dots, pkgs, ... }:

{

    packages = [ pkgs.fish ];

    xdg_config."fish/functions".src = dots.get "fish";
    xdg_config."fish/conf.d/__moonstep.fish".src =
        dots.get "fish/conf.d/__moonstep.fish";

}
