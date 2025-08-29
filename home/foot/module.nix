{ lib, dots, pkgs, ... }:

let

    configuredDropDownAlike =
        pkgs.tsuki.kde.drop-down-alike {
            resource_class = "foot";
            command = lib.getExe pkgs.foot;
            command_args = [ "--working-directory=." ];
        };

in

{

    packages = with pkgs; [
        foot
        ( lib.getOutput "busnaguri" pkgs.tsuki.inori )
        configuredDropDownAlike
    ];

    xdg_config."foot/foot.ini".src = dots.get "foot/foot.ini";

}
