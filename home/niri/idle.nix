{ lib, pkgs, ... }:

{

    xdg_config."hypr/hypridle.conf".text = ''
        general {
            before_sleep_cmd = niri msg action power-off-monitors
            after_sleep_cmd = niri msg action power-on-monitors
        }

        listener {
            timeout = 300   # 5min
            on-timeout = niri msg action power-off-monitors
            on-resume = niri msg action power-on-monitors
        }
    '';

    xdg_config."systemd/user/hypridle.service".text = ''
        [Unit]
        Description=Hyprland's idle daemon
        Documentation=https://wiki.hyprland.org/Hypr-Ecosystem/hypridle
        PartOf=graphical-session.target
        After=graphical-session.target noctalia.service

        [Service]
        Type=simple
        ExecStart=${lib.getExe pkgs.hypridle}
        Restart=on-failure

        [Install]
        WantedBy=graphical-session.target
    '';

    xdg_config."systemd/user/sway-audio-idle-inhibit.service".text = ''
        [Unit]
        Description=SwayAudioIdleInhibit daemon
        Documentation=https://github.com/ErikReider/SwayAudioIdleInhibit
        PartOf=graphical-session.target
        After=graphical-session.target noctalia.service
        ConditionEnvironment=WAYLAND_DISPLAY

        [Service]
        Type=simple
        ExecStart=${lib.getExe pkgs.sway-audio-idle-inhibit}
        Restart=on-failure

        [Install]
        WantedBy=graphical-session.target
    '';

}
