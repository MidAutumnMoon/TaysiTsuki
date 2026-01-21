{ dots, pkgs, flakes, ... }:

{

    packages = with pkgs; [
        flakes.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];

    xdg_config."noctalia".src = dots.get "noctalia";

}
