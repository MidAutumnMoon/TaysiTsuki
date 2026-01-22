{ dots, pkgs, ... }:

{

    packages = with pkgs; [
        tsuki.nushell
    ];

    xdg_config."nushell".src = dots.get "nushell";

}
