{ lib, pkgs, ... }:

let

    xdg_vars = {
        XDG_DATA_HOME = "$HOME/.local/share";
        XDG_STATE_HOME = "$HOME/.local/state";
        XDG_CACHE_HOME = "$HOME/.cache";
        XDG_CONFIG_HOME = "$HOME/.config";
    };

in

{
    environment.defaultPackages = lib.mkDefault [];

    environment.systemPackages =
        with pkgs; [
            fd
            ripgrep
            file
            htop
            rsync
            strace
        ];

    environment.variables =
        xdg_vars
        // {
            GLIBC_TUNABLES = "glibc.elision.enable=1:glibc.malloc.hugetlb=1";
        };

    environment.etc = {
        "pam/environment".text =
            xdg_vars
            |> lib.mapAttrs ( _: lib.replaceStrings ["$HOME"] ["@{HOME}"] )
            |> lib.mapAttrsToList ( n: v: ''${n} DEFAULT="${v}"'' )
            |> lib.concatStringsSep "\n"
            |> lib.mkAfter;
    };
}
