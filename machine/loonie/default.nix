{ lib, pkgs, ... }:

let

    selfUsername = "teapot";

in {

    imports = [
        ./rclone
    ];

    programs = {
        nh = {
            enable = true;
            flake = "/home/teapot/Nuran/";
        };
        direnv.enable = true;
    };

    environment.systemPackages = [
        pkgs.neovim_teapot
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

    fileSystems."/mnt/z" = {
        device = "Z:";
        fsType = "drvfs";
        options = [ "defaults" "async" "noatime" "metadata" "nofail" ];
    };

    networking = {
        hostName = "loonie";
        useDHCP = false;

        # WSL kernel doesn't come with necessary module to run nftables,
        # besides, Windows already has firewall configured anyway.
        firewall.enable = lib.mkForce false;

        proxy.default = "http://ren.home.lan:7890";
    };

    services.resolved.enable = false;

    nix.nixPath = [
        "nulib=/home/teapot/Nuran/lib"
    ];

    sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

}
