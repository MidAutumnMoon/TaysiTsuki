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
        tsuki.inori
        tsuki.opentofu
        sops
        libtree
    ];

    envvars = {
        HISTFILE = "$XDG_STATE_HOME/bash_history";
        LESSHISTFILE = "$XDG_STATE_HOME/less_history";
    };

}
