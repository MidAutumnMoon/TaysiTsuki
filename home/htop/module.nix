# lny module — symlinks repo home/htop/htoprc -> $XDG_CONFIG_HOME/htop/htoprc
{ dots, ... }:

{

    xdg_config."htop/htoprc".src = dots.get "htop/htoprc";

}
