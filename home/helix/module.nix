# lny module: install helix; symlinks home/helix dir -> $xdg_config_home/helix
{ pkgs, dots, ... }:

{

    packages = with pkgs; [
        tsuki.helix
        ripgrep
        fd
        skim
        nixd
    ];

    xdg_config."helix".src = dots.get "helix";

}
