# lny module — installs zed + package-version-server; symlinks repo home/zed (dir) -> $XDG_CONFIG_HOME/zed
{ dots, pkgs, ... }:

{

    packages = with pkgs; [
        tsuki.zed
        package-version-server
    ];

    xdg_config."zed".src = dots.get "zed";

}
