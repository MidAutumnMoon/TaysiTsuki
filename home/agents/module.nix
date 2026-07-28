# lny module — symlinks repo home/agents (dir) -> $HOME/.agents
{ dots, pkgs, ... }:

{

    home.".agents".src = dots.get "agents";

    packages = with pkgs; [
        tsuki.playwright-cli
    ];

}
