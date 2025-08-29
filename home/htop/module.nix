{ dots, pkgs, ... }:

{

    xdg_config."htop/htoprc".src = dots.get "htop/htoprc";

}
