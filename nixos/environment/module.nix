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
        GLIBC_TUNABLES = "glibc.malloc.hugetlb=1:glibc.elf.thp=1";
        MALLOC_CONF = "thp:always,metadata_thp:always";
        MIMALLOC_ALLOW_THP = "2";
    };
}
