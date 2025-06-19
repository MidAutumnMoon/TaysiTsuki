{ dots, pkgs, ... }:

{

    packages = [ pkgs.atuin ];

    xdg_config."atuin/config.toml".src = dots.get "atuin/config.toml";

}
