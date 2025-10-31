{ pkgs, ... }:

let

    obsidianBinElectron =
        pkgs.obsidian.override {
            electron = pkgs.electron-bin;
        };

in

{

    environment.systemPackages = with pkgs; [
        fastfetchMinimal
        git
        cifs-utils
        strawberry
        wl-clipboard
        telegram-desktop
        mpv
        obsidianBinElectron
        unrar
        numbat
        nix-tree
    ];

    environment.variables = {
        KWIN_USE_OVERLAYS = 1;
        POWERDEVIL_NO_DDCUTIL = 1;
    };

}
