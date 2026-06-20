# lny module — installs nvim toolchain; symlinks repo home/nvim dir -> $XDG_CONFIG_HOME/nvim
{ pkgs, dots, ... }:

{

    packages = with pkgs; [
        tsuki.neovim
        ripgrep
        fd
        # parinfer-rust
        skim
        nixd
        # lua-language-server
    ];

    xdg_config."nvim".src = dots.get "nvim";

}
