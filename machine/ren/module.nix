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
        extraGroups = [
            "wheel"
            config.hardware.i2c.group
        ];
        uid = 1000;
        password = "Moon";
        openssh.authorizedKeys.keys = [ config.lore.pubkeys.teapot ];
        lny = { imports = lib.listAllModules ../../home; };
    };

    nix.settings.trusted-users = [
        config.users.users."teapot".name
    ];

    nix.settings.substituters = lib.mkAfter [
        "https://attic.xuyh0120.win/lantian"
        "https://cache.numtide.com"
    ];

    nix.settings.trusted-public-keys = lib.mkAfter [
        "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc="
        "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
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

    boot.machineId = "4918e038ffe84b618de01b10861eca7f";

    hardware = {
        cpu.amd.updateMicrocode = true;
        enableRedistributableFirmware = true;
    };

    nixpkgs.hostPlatform = "x86_64-linux";

}
