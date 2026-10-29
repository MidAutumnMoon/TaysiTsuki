{ lib, pkgs, ... }:

{
    environment.defaultPackages = lib.mkDefault [];

    environment.systemPackages = with pkgs; [
        fd
        ripgrep
        file
        htop
        rsync
        strace
        lsof
    ];

    environment.pathsToLink = [
        "/share/mpv"
    ];

    environment.sessionVariables = {
        XDG_DATA_HOME = "$HOME/.local/share";
        XDG_STATE_HOME = "$HOME/.local/state";
        XDG_CACHE_HOME = "$HOME/.cache";
        XDG_CONFIG_HOME = "$HOME/.config";
    };

    environment.variables = {
        GLIBC_TUNABLES = "glibc.elision.enable=1:glibc.malloc.hugetlb=1";
    };
}
