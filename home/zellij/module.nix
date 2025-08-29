{ dots, pkgs, ... }:

{

    packages = with pkgs; [
        zellij
    ];

    xdg_config."zellij".src = dots.get "zellij";

    xdg_config."fish/conf.d/__zellij.fish".src =
        dots.get "zellij/__zellij.fish";

}
