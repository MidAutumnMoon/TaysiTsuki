{ lib, dots, pkgs, ... }:

{

    packages = with pkgs; [
        foot
    ];

    xdg_config."foot/foot.ini".src = dots.get "foot/foot.ini";

}
