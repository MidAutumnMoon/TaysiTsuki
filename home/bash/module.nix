# lny module — symlinks repo home/bash/bashrc.bash -> $HOME/.bashrc
{ dots, ... }:

{

    home.".bashrc".src = dots.get "bash/bashrc.bash";

}
