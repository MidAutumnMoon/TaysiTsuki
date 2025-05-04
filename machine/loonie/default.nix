{ lib, pkgs, ... }:

let

    selfUsername = "teapot";

in {

    imports = [
        ./rclone
        ./shell.nix
    ];

    programs = {
        nh = {
            enable = true;
            flake = "/home/teapot/TaysiTsuki";
        };
        fish.enable = true;
    };

    programs.direnv = {
        enable = true;
        settings = {
            global.warn_timeout = "10s";
            global.strict_env = true;
        };
    };

    environment.systemPackages = with pkgs; [
        tsuki.neovim
        numbat
        restic
    ];

    home-manager.users.${selfUsername} = import ./home.nix;

    wsl = {
        enable = true;
        defaultUser = selfUsername;
        wslConf = {
            user.default = selfUsername;
        };
        interop = {
            includePath = false;
        };
    };

    hardware.graphics.enable = lib.mkForce false;

    fileSystems."/mnt/z" = {
        device = "Z:";
        fsType = "drvfs";
        options = [ "defaults" "async" "noatime" "metadata" "nofail" ];
    };

    fileSystems."/home/teapot/Hotaru" = {
        device = "/mnt/c/Users/Hotaru";
        fsType = "none";
        depends = [ "/mnt/c" ];
        options = [
            "bind" "nofail"
        ];
    };

    system.etc.overlay.enable = lib.mkForce false;

    networking = {
        hostName = "loonie";
        useDHCP = false;

        # WSL kernel doesn't come with necessary module to run nftables,
        # besides, Windows already has firewall configured anyway.
        firewall.enable = lib.mkForce false;

        proxy.default = "http://ren.home.lan:7890";
    };

    services.resolved.enable = false;

    sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

    nix.settings.trusted-users = [ selfUsername ];

}
