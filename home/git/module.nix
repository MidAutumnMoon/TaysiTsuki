{ lib, nixosCfg, pkgs, ... }:

# Excellent material for configuring git:
# https://blog.gitbutler.com/how-git-core-devs-configure-git/

let

    inherit ( pkgs )
        writeText
    ;

    allowedSigners = writeText "git-allowed-signers" ''
        me@418.im ${nixosCfg.lore.pubkeys.teapot}
    '';

in {

    packages = with pkgs; [ git ];

    xdg_config."git/config".text = ''
        [user]
            email = "me@418.im"
            name = "MidAutumnMoon"

        [merge]
            conflictstyle = "diff3"

        [diff]
            mnemonicPrefix = true
            renames = true
            algorithm = histogram
            colorMoved = plain

        [branch]
            sort = -committerdate

        [tag]
            sort = version:refname

        [pull]
            rebase = true


        [push]
            default = simple
            # Auto create branches and tag on remote
            # might cause problem?
            autoSetupRemote = true
            followTags = true

        [fetch]
            prune = true
            pruneTags = true
            all = true

        [rebase]
            autoSquash = true
            autoStash = true
            updateRefs = true

        [status]
            showUntrackedFiles = "all"

        [init]
            defaultBranch = "master"

        [core]
            quotePath = false
            pager = "${lib.getExe pkgs.delta}"
            # fsmonitor = "{lib.getExe pkgs.rs-git-fsmonitor}"
            # untrackedCache = true

        [credential]
            helper = "store --file=${nixosCfg.sops.secrets
                ."token--github--me".path}"

        [gc]
            auto = 0

        [interactive]
            diffFilter = delta --color-only

        [delta]
            navigate = true
            hyperlinks = true
            line-numbers = true;

        [column]
            ui = auto

        [help]
            autocorrect = prompt

        [commit]
            verbose = true

        [rerere]
            enabled = true
            autoupdate = true


        # Alias

        [alias]
            kill-reflog = "reflog expire --all --expire=now --expire-unreachable=now"


        # Signing

        [user]
            signingKey = "${nixosCfg.sops.secrets."key--ssh--teapot".path}"

        [gpg]
            format = "ssh"

        [gpg "ssh"]
            allowedSignersFile = "${allowedSigners}"

        [commit]
            gpgSign = true

        [tag]
            gpgSign = true

    '';

}

# vim: nowrap:
