# lny module — installs jujutsu; writes $XDG_CONFIG_HOME/jj/config.toml
# Ports the user/diff/pager/signing settings from home/git/module.nix.
{ lib, nixosCfg, pkgs, ... }:

let
    # Same allowed-signers file as git: "email pubkey" per line.
    # jj's SSH backend uses this for signature verification.
    allowedSigners = pkgs.writeText "jj-allowed-signers" ''
        me@418.im ${nixosCfg.lore.pubkeys.teapot}
    '';

    # The tool ui.diff-formatter (config.toml) points to. [merge-tools.difftastic]
    # stays for jj diff --tool difftastic.
    difftty = pkgs.writeShellScript "difftty" ''
        # jj pipes the tool's stdout, so isatty(1) is always false here; test
        # jj's fd 1 instead, which stays on the terminal even while paging.
        set -u
        case "$(readlink "/proc/$PPID/fd/1" 2>/dev/null)" in
            /dev/pts/*|/dev/tty*|/dev/console)
                # 0-column pty panics difftastic (difftastic#1064)
                exec ${lib.getExe pkgs.difftastic} --color=always --width "$(( $1 > 0 ? $1 : 80 ))" "$2" "$3"
                ;;
            *)
                base=$(basename "$2")
                exec ${lib.getExe' pkgs.diffutils "diff"} -u --label "a/$base" --label "b/$base" "$2" "$3"
                ;;
        esac
    '';

in {

    packages = [ pkgs.jujutsu ];

    # Put most of the config in TOML to avoid quote escaping problems.
    xdg_config."jj/config.toml".text = ''
        # git: commit.gpgSign = true, gpg.format = ssh,
        # user.signingKey = (private key path)
        # jj's signing.key is the *public* key. ssh-keygen -Y sign -f
        # <key.pub> derives the private key path by stripping .pub, so
        # it finds ~/.ssh/id_teapot next to id_teapot.pub (both created
        # by home/ssh). jj expands ~ at runtime; $HOME does not work.
        [signing]
        behavior = "own"
        backend = "ssh"
        key = "~/.ssh/id_teapot.pub"
        backends.ssh.allowed-signers = "${allowedSigners}"

        [merge-tools.difftastic]
        program = "${lib.getExe pkgs.difftastic}"
        # jj's pipes hide the terminal from difftastic, whose width
        # detection then falls back to 80 cols; $width is jj's own
        # measured terminal width.
        diff-args = ["--color=always", "--width", "$width", "$left", "$right"]
        diff-invocation-mode = "file-by-file"

        [merge-tools.difftty]
        program = "${difftty}"
        diff-args = ["$width", "$left", "$right"]
        diff-invocation-mode = "file-by-file"
        # diff(1) exits 1 on differences; only trouble (2) should warn.
        diff-expected-exit-codes = [0, 1]

        ${lib.fileContents ./config.toml}
    '';

}
