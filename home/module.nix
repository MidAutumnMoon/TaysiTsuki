{ pkgs, tsukiObservatory, ... }:

{

    _module.args = rec {
        tsukiObservatory = "{{ home }}/TaysiTsuki";

        # convinient function to get a file from dotfile dir
        dots = {
            __toString = _self: "${tsukiObservatory}/home";
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
        #yacreader
        # TODO: remove
        imagemagick
        # TODO: remove
        restic
        rsgain
        harper
        mtr
        ncdu
        shellcheck
        bash-language-server
        gh
        tsuki.deno
        wgsl-analyzer
        easyeffects
        age
        tsuki.feishin
        # tsuki.opencode
        cherry-studio
    ];

    envvars = {
        HISTFILE = "$XDG_STATE_HOME/bash_history";
        LESSHISTFILE = "$XDG_STATE_HOME/less_history";
        GTK2_RC_FILES = "$XDG_CONFIG_HOME/gtk-2.0/gtkrc";
    };

    xdg_config."harper-ls/dictionary.txt".src =
        "${tsukiObservatory}/.harper-dictionary.txt";

}
