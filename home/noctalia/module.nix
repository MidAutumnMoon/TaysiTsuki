{ dots, pkgs, ... }:

{

    packages = with pkgs; [
        noctalia-shell
    ];

    xdg_config."noctalia".src = dots.get "noctalia";

}
