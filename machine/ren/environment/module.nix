{ pkgs, ... }:

{

    environment.systemPackages = with pkgs; [
        fastfetchMinimal
        git
        cifs-utils
        strawberry
        wl-clipboard
        telegram-desktop
        mpv
        obsidian
        unrar
        numbat
        tsuki.qimgv
        nix-tree
        deno
    ];

}
