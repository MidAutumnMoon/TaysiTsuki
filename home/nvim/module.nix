{ pkgs, dots, ... }:

{

    packages = with pkgs; [
        tsuki.neovim
        ripgrep
        fd
        parinfer-rust
        skim
        nixd
    ];

    xdg_config."nvim".src = dots.get "nvim";

}
