{ pkgs, lib, ... }:

let

    # This avoids to build plasma-workspace.
    appMenu = pkgs.runCommand "app-menu" {} ''
        tar xvf "${pkgs.kdePackages.plasma-workspace.src}"
        find -name "plasma-applications.menu" -exec cp {} "$out" \;
    '';

in {
    programs.niri = {
        enable = true;
        useNautilus = false;
        package = pkgs.tsuki.niri;
    };

    programs.noctalia = {
        enable = true;
        systemd.enable = true;
        recommendedServices.enable = false;
    };

    environment.systemPackages = with pkgs; [
        kdePackages.breeze
        kdePackages.breeze-icons
        kdePackages.breeze-gtk
        nwg-look
        adwaita-icon-theme
    ];

    services.power-profiles-daemon.enable = true;
    services.upower.enable = true;
    hardware.i2c.enable = true;
    services.udisks2.enable = true;

    xdg.icons.enable = true;
    xdg.icons.fallbackCursorThemes = [ "breeze_cursors" ];

    # ref: https://github.com/NixOS/nixpkgs/issues/409986
    environment.etc."xdg/menus/applications.menu".source = appMenu;

    systemd.user.services."trigger-kbuildsycoca6" = {
        description = "Trigger kbuildsycoca6 manually";

        wantedBy = [ "nixos-activation.service" ];
        after = [ "nixos-activation.service" ];
        stopIfChanged = false;

        serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = false;
        };

        script = ''
            ${lib.getExe pkgs.kdePackages.kservice} --noincremental
        '';
    };

    services.system76-scheduler.enable = true;

    # systemd.services."system76-scheduler" = {
    #     environment = {
    #         RUST_LOG = "debug";
    #     };
    # };

    systemd.user.services."system76-scheduler-niri" = {
        description = "Niri integration for system76-scheduler";
        after = [ "niri.service" ];
        requires = [ "niri.service" ];
        wantedBy = [ "default.target" ];
        serviceConfig = {
            Type = "simple";
            ExecStart = lib.getExe pkgs.tsuki.system76-scheduler-niri;
            Restart = "on-failure";
        };
    };

    services.displayManager.noctalia-greeter = {
        enable = true;
        settings = {
            user.default = "teapot";
            auth.allow_empty_password = true;
        };
    };

    services.orca.enable = false;
    services.geoclue2.enable = false;
    services.fwupd.enable = false;
    services.speechd.enable = false;

    i18n.inputMethod = {
        enable = true;
        type = "fcitx5";
        fcitx5 = {
            addons = with pkgs; [
                fcitx5-mozc
                kdePackages.fcitx5-chinese-addons
            ];
            waylandFrontend = true;
        };
    };

}
