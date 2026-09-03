# lny module — installs jujutsu; writes $XDG_CONFIG_HOME/jj/config.toml
# Ports the user/diff/pager/signing settings from home/git/module.nix.
{ lib, nixosCfg, pkgs, ... }:

let
    # Same allowed-signers file as git: "email pubkey" per line.
    # jj's SSH backend uses this for signature verification.
    allowedSigners = pkgs.writeText "jj-allowed-signers" ''
        me@418.im ${nixosCfg.lore.pubkeys.teapot}
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
        diff-args = ["--color=always", "$left", "$right"]
        diff-invocation-mode = "file-by-file"

        ${lib.fileContents ./config.toml}
    '';

}
