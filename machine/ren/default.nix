{ config, pkgs, ... }:

{

    imports = [
        ./services/adguardhome.nix
        ./services/caddy.nix
        ./services/mihomo.nix
    ];

    networking = {
        hostName = "ren";
        proxy.default =
            "http://127.0.0.1:${toString config.lore.ports.mihomo_listen}";
        useDHCP = true;
    };

    documentation = {
        enable = false;
        man.enable = false;
    };

    #
    # preservation & sops
    #

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

    systemd.suppressedSystemUnits = [ "systemd-machine-id-commit.service" ];

    sops.age.sshKeyPaths = [ "/persist/etc/ssh/ssh_host_ed25519_key" ];

    #
    # filesystems
    #

    zramSwap.enable = true;

    fileSystems = let
        btrfsDevice = "/dev/disk/by-uuid/dd3d01c1-9010-435a-85d8-a2f0a1815433";
        btrfsOptionFor = subvol: [
            "subvol=${subvol}"
            "compress-force=zstd"
            "noatime"
        ];
    in {
        "/" = {
            device = "none";
            fsType = "tmpfs";
            options = [ "defaults,mode=755,nosuid,nodev,size=4G" ];
        };
        "/boot" = {
            device = "/dev/disk/by-uuid/B6AC-C76F";
            fsType = "vfat";
            options = [ "fmask=0022" "dmask=0022" ];
        };
        "/nix" = {
            device = btrfsDevice;
            fsType = "btrfs";
            options = btrfsOptionFor "nix";
        };
        "/var" = {
            device = btrfsDevice;
            fsType = "btrfs";
            options = btrfsOptionFor "var";
        };
        "/persist" = {
            device = btrfsDevice;
            fsType = "btrfs";
            options = btrfsOptionFor "persist";
            neededForBoot = true;
        };
        "/root" = {
            device = btrfsDevice;
            fsType = "btrfs";
            options = btrfsOptionFor "root";
        };
    };

    #
    # Hardware configs
    #

    boot.initrd = {
        availableKernelModules = [
            "nvme"
            "xhci_pci"
            "ahci"
            "usbhid"
            "usb_storage"
            "sd_mod"
            # "rtsx_usb_sdmmc"
        ];
        includeDefaultModules = false;
        systemd.enable = true;
    };

    boot.loader ={
        systemd-boot.enable = true;
        efi.canTouchEfiVariables = true;
    };

    boot.kernelModules = [
        "amdgpu"
        "kvm-amd"
    ];

    boot.kernelParams = [ "amd_pstate=active" ];

    hardware ={
        cpu.amd.updateMicrocode = true;
        enableRedistributableFirmware = true;
    };

    nixpkgs.hostPlatform = "x86_64-linux";

}

