{ dots, pkgs, ... }:

{

    packages = with pkgs; [
        swayimg
    ];

    xdg_config."swayimg/config".src = dots.get "swayimg/swayimgrc.ini";

}
