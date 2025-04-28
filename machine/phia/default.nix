{ lib, config, pkgs, ... }:

let

    phiaSuite = pkgs.callPackage ./packages {};

in

{

    imports = [
        ./services/samba.nix
        ./services/caddy.nix
        ./services/torrent.nix
    ];

    networking = {
        hostName = "phia";
        hostId = "0a3e0a19";
        proxy.default =
            "http://ren.home.lan:${toString config.lore.ports.mihomo_listen}";
        useDHCP = true;
        tempAddresses = "disabled";
    };

    environment.systemPackages = with pkgs; [
        fastfetch_teapot
        hdparm
        ncdu
        rclone
        smartmontools
        phiaSuite.allSuiteCombined
    ];

    passthru.phiaSuite = phiaSuite;

    security.sudo.wheelNeedsPassword = false;

    # Avoid using nobody
    users.users."fileshare" = {
        isNormalUser = true;
        # better come up with another way to handle samba share
        # filesystem permission ...
        extraGroups = [ "wheel" ];
        openssh.authorizedKeys.keys = [ config.lore.pubkeys.teapot ];
    };

    # programs

    programs.fish = {
        enable = true;
    };

    environment.shellAliases = {
        "sys" = "systemctl";
    };

    # preservation & sops

    preservation.enable = true;

    preservation.preserveAt."/persist" = {
        files = [
            { file = "/etc/ssh/ssh_host_ed25519_key"; mode = "0600"; }
            { file = "/etc/ssh/ssh_host_ed25519_key.pub"; mode = "0644"; }
            { file = "/etc/ssh/ssh_host_rsa_key"; mode = "0600"; }
            { file = "/etc/ssh/ssh_host_rsa_key.pub"; mode = "0644"; }
            { file = "/etc/machine-id"; mode = "0444"; inInitrd = true; }
        ];
        directories = [];
    };

    sops.age.sshKeyPaths = [ "/persist/etc/ssh/ssh_host_ed25519_key" ];

    systemd.suppressedSystemUnits = [
        "systemd-machine-id-commit.service"
    ];

    #
    # filesystems
    #

    zramSwap.enable = true;

    fileSystems = {
        "/" = {
            device = "none";
            fsType = "tmpfs";
            options = [ "defaults" "mode=755" "nosuid" "nodev" "size=8G" ];
        };
        "/boot" = {
            device = "/dev/disk/by-uuid/3C67-B074";
            fsType = "vfat";
            options = [ "fmask=0022" "dmask=0022" ];
        };
        "/nix" = {
            device = "phia/nix";
            fsType = "zfs";
        };
        "/var" = {
            device = "phia/var";
            fsType = "zfs";
        };
        "/persist" = {
            device = "phia/persist";
            fsType = "zfs";
            neededForBoot = true;
        };
        "/root" = {
            device = "phia/root";
            fsType = "zfs";
        };
        "/home" = {
            device = "phia/home";
            fsType = "zfs";
        };
        "/srv" = {
            device = "phia/srv";
            fsType = "zfs";
        };
        "/srv/pool" = {
            device = "phia/srv/pool";
            fsType = "zfs";
        };
        "/srv/torrent" = {
            device = "phia/srv/torrent";
            fsType = "zfs";
        };
    };

    systemd.tmpfiles.rules = let
        inherit ( config.sops ) secrets;
        inherit ( config.users.users ) fileshare;
        poolMpt = config.fileSystems."/srv/pool".mountPoint;
        torrentMpt = config.fileSystems."/srv/pool".mountPoint;
    in [
        "d ${poolMpt} 0755 ${fileshare.name} ${fileshare.group} - -"
        "d ${torrentMpt} 0755 ${fileshare.name} ${fileshare.group} - -"
        "C /etc/rclone.conf - - - - ${secrets."conf--rclone".path}"
        "z /etc/rclone.conf 0440 ${fileshare.name} ${fileshare.group} - -"
    ];

    services.zfs.autoScrub.enable = true;
    services.zfs.trim.enable = true;

    #
    # Hardware configs
    #

    boot.initrd = {
        availableKernelModules = [
            "ahci"
            "xhci_pci"
            "usbhid"
            "usb_storage"
            "sd_mod"
        ];
        includeDefaultModules = false;
        systemd.enable = true;
    };

    boot.kernelPackages = lib.mkForce pkgs.linuxPackages;

    boot.loader = {
        systemd-boot.enable = true;
        efi.canTouchEfiVariables = true;
    };

    boot.kernelModules = [ "kvm-intel" ];

    hardware = {
        cpu.intel.updateMicrocode = true;
        enableRedistributableFirmware = true;
    };

    nixpkgs.hostPlatform = "x86_64-linux";

}

