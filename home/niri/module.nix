{ dots, pkgs, ... }:

{

    packages = with pkgs; [
        kdePackages.dolphin
        kdePackages.dolphin-plugins
        kdePackages.ffmpegthumbs
    ];

    xdg_config."niri".src = dots.get "niri";

}
