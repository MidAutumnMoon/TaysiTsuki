{ pkgs, ... }:

{

    environment.systemPackages = with pkgs; [
        microfetch
        git
        # cifs-utils
        wl-clipboard
        telegram-desktop
        mpv
        # obsidian
        unrar
        numbat
        nix-tree
        nvme-cli
        smartmontools
    ];

}
