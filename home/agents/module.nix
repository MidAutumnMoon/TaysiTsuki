# lny module — symlinks repo home/agents (dir) -> $HOME/.agents
{ dots, ... }:

{

    home.".agents".src = dots.get "agents";

}
