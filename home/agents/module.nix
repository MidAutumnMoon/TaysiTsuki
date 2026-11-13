# lny module — symlinks repo home/agents (dir) -> $HOME/.agents
{ dots, pkgs, ... }:

{

    home.".agents".src = dots.get "agents";
    home.".zcode/AGENTS.md".src = dots.get "agents/AGENTS.md";
    home.".omp/agent/RULES.md".src = dots.get "agents/AGENTS.md";
    home.".gemini/AGENTS.md".src = dots.get "agents/AGENTS.md";

    packages = with pkgs; [
        tsuki.playwright-cli
    ];

}
