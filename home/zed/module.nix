{ dots, pkgs, ... }:

{

    packages = [ pkgs.zed-editor ];

    xdg_config."zed".src = dots.get "zed";

}
