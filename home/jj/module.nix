# lny module — installs jujutsu; writes $XDG_CONFIG_HOME/jj/config.toml
# Ports the user/diff/pager/signing settings from home/git/module.nix.
{ lib, nixosCfg, pkgs, dots, ... }:

let

    allowedSigners =
        pkgs.writeText "jj-allowed-signers" ''
            me@418.im ${nixosCfg.lore.pubkeys.teapot}
        '';

in {

    packages = [ pkgs.jujutsu ];

    xdg_config."jj/config.toml".src = dots.get "jj/config.toml";

    xdg_config."jj/conf.d/nix.toml".text = /* toml */ ''
        [signing]
        backends.ssh.allowed-signers = "${allowedSigners}"

        [ui]
        pager = "${lib.getExe pkgs.delta}"
    '';

}
