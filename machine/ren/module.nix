{ lib, config, pkgs, ... }:

{

    #
    # Services
    #

    services.tailscale = {
        enable = true;
        openFirewall = true;
    };

    services.caddy.enable = true;
    services.avahi.enable = true;

    #
    # Programs
    #

    programs.direnv = {
        enable = true;
        settings = {
            global.warn_timeout = "10s";
            global.strict_env = true;
        };
    };

    programs.nh = {
        enable = true;
        flake = "/home/teapot/TaysiTsuki";
    };

    #
    # Users
    #

    users.users."teapot" = {
        isNormalUser = true;
        extraGroups = [ "wheel" ];
        uid = 1000;
        password = "Moon";
        openssh.authorizedKeys.keys = [ config.lore.pubkeys.teapot ];
        lny = { imports = lib.listAllModules ../../home; };
    };

    nix.settings.trusted-users = [
        config.users.users."teapot".name
    ];

    security.pam.u2f = {
        enable = true;
        settings = {
            # interactive = true;
            cue = true;
            origin = "pam://tsuki";
            authfile = pkgs.copyPathToStore ./secrets/u2f_keys;
        };
    };

    security.pam.services = {
        login.u2fAuth = true;
        sudo.u2fAuth = true;
    };

    #
    # Desktop
    #

    # N.B. single leading space
    services.udev.extraHwdb = ''
        # switch caplock and esc (because vim)
        # switch left meta and ctrl (because vim)
        # esc -> capslock : KEYBOARD_KEY_70029=key_capslock
        evdev:atkbd:*
        evdev:input:b0003v3151p4015*
         KEYBOARD_KEY_70039=key_esc
         KEYBOARD_KEY_700e3=key_leftctrl
         KEYBOARD_KEY_700e0=key_leftmeta

        # map one of the mouse's side button to middle click
        # (because the middle button is rock hard to press)
        evdev:input:b0003v30FAp1701*
         KEYBOARD_KEY_90005=btn_middle
    '';

    boot.machineId = "4918e038ffe84b618de01b10861eca7f";

    hardware = {
        cpu.amd.updateMicrocode = true;
        enableRedistributableFirmware = true;
    };

    # ren is a server which also happends to run desktop
    # don't sleep
    systemd.sleep.extraConfig = ''
        AllowSuspend = no
        AllowHibernation = no
        AllowHybridSleep = no
        AllowSuspendThenHibernate = no
    '';

    nixpkgs.hostPlatform = "x86_64-linux";

}
