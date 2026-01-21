{ dots, pkgs, ... }:

{

    packages = with pkgs; [
        noctalia-shell
    ];

    xdg_config."niri/config.kdl".src = dots.get "niri/config.kdl";

}
