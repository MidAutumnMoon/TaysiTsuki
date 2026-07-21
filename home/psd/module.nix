# lny module — installs profile-sync-daemon config; symlinks repo home/psd/psd.conf  -> $XDG_CONFIG_HOME/psd/psd.conf
{ dots, ... }:

{
    xdg_config."psd/psd.conf".src = dots.get "psd/psd.conf";
}
