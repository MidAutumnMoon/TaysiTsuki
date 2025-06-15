{ lib, config, pkgs, ... }:

let

    inherit ( config )
        lore
    ;

in

{

    imports = [
        ./dns.nix
        ./singbox.nix
        ./fish
        ./rclone.nix
    ];

    #
    # General
    #

    environment.systemPackages = with pkgs; [
        fastfetchMinimal
        git
        tsuki.firefox
        cifs-utils
        # sort out mpv later
        strawberry
        wl-clipboard
        telegram-desktop
        mpv
        obsidian
        unrar
        numbat
        restic
        zed-editor
    ];

    networking = {
        hostName = lore.machines.ren.hostname;
        proxy.default = "http://localhost:${toString lore.ports.proxyPort}";
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

    services.avahi = {
        enable = true;
        openFirewall = true;
        nssmdns4 = true;
        nssmdns6 = true;
        publish.enable = true;
        publish.addresses = true;
        publish.domain = true;
    };

    services.scx = {
        enable = true;
        scheduler = "scx_bpfland";
    };

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

    programs.fish.enable = true;

    #
    # Users
    #

    users.users."teapot" = {
        isNormalUser = true;
        extraGroups = [ "wheel" ];
        uid = 1000;
        password = "Moon";
        openssh.authorizedKeys.keys = [ config.lore.pubkeys.teapot ];
    };

    nix.settings.trusted-users = [
        config.users.users."teapot".name
    ];

    home-manager.users."teapot" = import ./home.nix;

    security.sudo.wheelNeedsPassword = false;

    #
    # Desktop
    #

    services.displayManager.sddm = {
        enable = true;
        wayland.enable = true;
        settings.General.DisplayServer = "wayland";
    };

    services.desktopManager.plasma6.enable = true;

    environment.plasma6.excludePackages =
        with pkgs.kdePackages; [
            elisa
            krdp
        ];

    programs.kde-pim.enable = false;

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

    security.rtkit.enable = true;

    services.pipewire = {
        extraConfig.pipewire."10-hires" = {
            "context.properties" = {
                "default.clock.allowed-rates" = [ 44100 48000 96000 192000 ];
                "default.clock.min-quantum" = 16;
            };
        };
        extraConfig.client."10-hires" = {
            "stream.properties" = {
                "resample.quality" = 10;
            };
        };
    };

    #
    # Filesystems
    #

    zramSwap = {
        enable = true;
        memoryPercent = 100;
    };

    fileSystems = let
        btrfsDevice =
            "/dev/disk/by-uuid/dd3d01c1-9010-435a-85d8-a2f0a1815433";
        btrfsOptionFor = subvol: [
            "subvol=${subvol}"
            "compress-force=zstd"
            "noatime"
        ];
        sambaOption = [
            "x-systemd.automount"
            "x-systemd.mount-timeout=30s"
            "_netdev"
            "user"
            "users"
            "uid=${toString config.users.users.teapot.uid}"
            "gid=${toString config.users.groups.users.gid}"
        ];
    in {

        "/" = {
            device = "none";
            fsType = "tmpfs";
            options = [ "defaults,mode=755,nosuid,nodev,size=4G" ];
        };
        "/mnt/z" = {
            device = "none";
            fsType = "tmpfs";
            options = [ "defaults,mode=777,size=100%,noatime" ];
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
        "/home" = {
            device = btrfsDevice;
            fsType = "btrfs";
            options = btrfsOptionFor "home";
        };
        "/mnt/pool" = {
            # TODO: no hardcode hostname and path
            device = "//phia.local/pool";
            fsType = "cifs";
            options = sambaOption ++ [];
        };
        "/mnt/torrent" = {
            # TODO: no hardcode hostname and path
            device = "//phia.local/torrent";
            fsType = "cifs";
            options = sambaOption ++ [];
        };
    };

    services.btrfs.autoScrub.enable = true;

    preservation = {
        enable = true;
        preserveAt."/persist" = {
            files = [
                { file = "/etc/ssh/ssh_host_ed25519_key"; mode = "0600"; }
                { file = "/etc/ssh/ssh_host_ed25519_key.pub"; mode = "0644"; }
                { file = "/etc/ssh/ssh_host_rsa_key"; mode = "0600"; }
                { file = "/etc/ssh/ssh_host_rsa_key.pub"; mode = "0644"; }
                { file = "/etc/machine-id"; mode = "0444"; inInitrd = true; }
            ];
            directories = [];
        };
    };

    systemd.suppressedSystemUnits = [ "systemd-machine-id-commit.service" ];

    sops.age.sshKeyPaths = [
        "/persist/etc/ssh/ssh_host_ed25519_key"
    ];

    #
    # Boot & handware
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

    boot.loader = {
        systemd-boot.enable = true;
        efi.canTouchEfiVariables = true;
    };

    boot.kernelModules = [
        "amdgpu"
        "kvm-amd"
        "cifs"
    ];

    boot.kernelParams = [ "amd_pstate=active" ];

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

