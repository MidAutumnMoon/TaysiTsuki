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
    ];

    environment.variables = {
        KWIN_USE_OVERLAYS = 1;
        POWERDEVIL_NO_DDCUTIL = 1;
    };

}
