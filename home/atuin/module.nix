# lny module — installs atuin; symlinks repo home/atuin/config.toml -> $XDG_CONFIG_HOME/atuin/config.toml
{ dots, pkgs, ... }:

{

    packages = [ pkgs.atuin ];

    xdg_config."atuin/config.toml".src = dots.get "atuin/config.toml";

}
