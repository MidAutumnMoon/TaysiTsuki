{ dots, pkgs, ... }:

{

    packages = with pkgs; [
        tsuki.monstar
    ];

    xdg_config."monstar/config".src = dots.get "monstar/config.ini";

}
