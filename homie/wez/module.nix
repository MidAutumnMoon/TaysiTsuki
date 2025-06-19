{ lib, dots, pkgs, ... }:

let

    configuredDropDownAlike =
        pkgs.tsuki.kde.drop-down-alike {
            resource_class = "org.wezfurlong.wezterm";
            command = lib.getExe pkgs.wezterm;
            command_args = [ "start" "--cwd" "." "--always-new-process" ];
        };

in

{

    packages = with pkgs; [
        wezterm
        tsuki.inori.busnaguri
        configuredDropDownAlike
    ];

    xdg_config."wezterm/wezterm.lua".src =
        dots.get "wez/wezterm.lua";

}
