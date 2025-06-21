{ pkgs, ... }:

{

    _module.args = rec {
        tsukiObservatory = "{{ home }}/TaysiTsuki";

        # convinient function to get a file from dotfile dir
        dots = {
            __toString = self: "${tsukiObservatory}/home";
            get = path: "${toString dots}/${path}";
        };
    };

    packages = with pkgs; [
        colmena
        fuc
        ( lib.getOutput "out" pkgs.tsuki.inori )
        tsuki.opentofu
        libtree
        picard
        sops
    ];

    envvars = {
        HISTFILE = "$XDG_STATE_HOME/bash_history";
        LESSHISTFILE = "$XDG_STATE_HOME/less_history";
        GTK2_RC_FILES = "$XDG_CONFIG_HOME/gtk-2.0/gtkrc";
    };

}
