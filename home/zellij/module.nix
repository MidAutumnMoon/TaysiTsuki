{ dots, pkgs, ... }:

{

    packages = with pkgs; [
        zellij
    ];

    xdg_config."zellij".src = dots.get "zellij";

}
