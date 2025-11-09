{ dots, pkgs, ... }:

{

    packages = with pkgs; [
        tsuki.zellij
    ];

    xdg_config."zellij".src = dots.get "zellij";

}
