{ dots, pkgs, ... }:

{

    packages = with pkgs; [
        swayimg
    ];

    xdg_config."swayimg/init.lua".src = dots.get "swayimg/init.lua";

}
