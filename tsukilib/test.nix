let
    # N.B. ignore unknow getFlake lsp error, it's a lsp bug
    flake = builtins.getFlake (toString ../.);

    pkgs = flake.packages.x86_64-linux;
in

with flake.lib;

#
# Before is the driver
# Below is the test body
#

bakeInit pkgs pkgs.zoxide "zsh" "zoxide init zsh"
