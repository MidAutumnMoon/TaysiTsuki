{ pkgs, lib, config,... }:

let

    # This avoids to build plasma-workspace.
    appMenu = pkgs.runCommand "app-menu" {} ''
        tar xvf "${pkgs.kdePackages.plasma-workspace.src}"
        find -name "plasma-applications.menu" -exec cp {} "$out" \;
    '';

in {
    programs.niri.enable = true;
    programs.niri.useNautilus = false;

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

    xdg.portal = {
        extraPortals = [ pkgs.kdePackages.xdg-desktop-portal-kde ];
        config.niri = {
            "org.freedesktop.impl.portal.FileChooser" = lib.mkForce "kde";
        };
    };

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
}
