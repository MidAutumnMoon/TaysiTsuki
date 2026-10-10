# lny module: install helix; symlinks home/helix dir -> $xdg_config_home/helix
{ pkgs, dots, ... }:

{

    packages = with pkgs; [
        helix
    ];

    xdg_config."helix".src = dots.get "helix";

}
