{ pkgs, ... }:

{
    users.users."root" = {
        lny = {
            xdg_config."nvim/init.lua".src =
                pkgs.copyPathToStore ../../../home/nvim/init.lua;
        };
    };
}
