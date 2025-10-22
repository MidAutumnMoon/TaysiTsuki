{ lib, config, pkgs, ... }:

let

    inherit ( config )
        lore
    ;

in

{

    #
    # General
    #

    networking = {
        hostName = lore.machines.ren.hostname;
        proxy.default = "http://localhost:${toString lore.ports.proxy}";
        tempAddresses = "disabled";
        useDHCP = false;
    };

    systemd.network.networks = {
        "10-enp3s0" = {
            name = "enp3s0";
            DHCP = "yes";
            networkConfig = {
                MulticastDNS = "resolve";
                DNSSEC = "no";
            };
        };
    };

    services.resolved.extraConfig = ''
        Cache = no
    '';

    #
    # Services
    #

    services.tailscale = {
        enable = true;
        openFirewall = true;
    };

    services.caddy.enable = true;
    services.avahi.enable = true;

    # services.scx = {
    #     enable = true;
    #     scheduler = "scx_bpfland";
    # };

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

    services.displayManager.sddm = {
        enable = true;
        wayland.enable = true;
        wayland.compositor = "kwin";
        settings.General.DisplayServer = "wayland";
    };

    services.desktopManager.plasma6.enable = true;

    environment.plasma6.excludePackages =
        with pkgs.kdePackages; [
            elisa
            krdp
            kwin-x11
            khelpcenter
            discover
            gwenview
            ( lib.getBin qttools )
        ];

    programs.kde-pim.enable = false;

    i18n.inputMethod = {
        enable = false;
        type = "fcitx5";
        fcitx5 = {
            addons = with pkgs; [
                fcitx5-mozc
                kdePackages.fcitx5-chinese-addons
            ];
            waylandFrontend = true;
        };
    };

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

    sops.age.sshKeyPaths = [
        "/persist/etc/ssh/ssh_host_ed25519_key"
    ];

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
