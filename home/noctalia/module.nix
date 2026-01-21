{ dots, pkgs, flakes, lib, ... }:

let

    noctalia = flakes
        .noctalia.packages.${pkgs.stdenv.hostPlatform.system}
        .default;
in

{

    packages = with pkgs; [
        noctalia
    ];

    xdg_config."noctalia".src = dots.get "noctalia";

    xdg_config."systemd/user/noctalia.service".text = ''
        [Unit]
        Description=Noctalia Shell Service
        PartOf=graphical-session.target
        Requisite=graphical-session.target
        After=graphical-session.target
        ConditionEnvironment=WAYLAND_DISPLAY

        [Service]
        ExecStart=${lib.getExe noctalia}
        Restart=on-failure
        RestartSec=1

        [Install]
        WantedBy=graphical-session.target
    '';

}
