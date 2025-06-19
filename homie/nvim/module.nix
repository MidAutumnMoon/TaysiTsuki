{ pkgs, dots, ... }:

{

    packages = with pkgs; [
        tsuki.neovim
        ripgrep
        fd
        parinfer-rust
        skim
    ];

    xdg_config."nvim".src = dots.get "nvim";

}
