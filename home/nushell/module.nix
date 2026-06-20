# lny module — installs nushell; symlinks repo home/nushell (dir) -> $XDG_CONFIG_HOME/nushell
{ dots, pkgs, ... }:

{

    packages = with pkgs; [
        tsuki.nushell
    ];

    xdg_config."nushell".src = dots.get "nushell";

}
