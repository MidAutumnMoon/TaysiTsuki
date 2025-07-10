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
        tsuki.qimgv
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

    #
    # Filesystems
    #

    zramSwap = {
        enable = true;
        memoryPercent = 100;
    };

    boot.initrd.luks.devices = {
        "rin" = {
            device = "/dev/disk/by-uuid/b0fb796a-6982-4c87-b261-80159d03946d";
            allowDiscards = true;
            bypassWorkqueues = true;
            crypttabExtraOpts = [ "fido2-device=auto" ];
        };
    };

    fileSystems = let
        btrfsDevice = "/dev/mapper/rin";
        btrfsOptionFor = subvol: [
            "subvol=${subvol}"
            "compress-force=zstd"
            "noatime"
        ];
        sambaOption = [
            "x-systemd.automount"
            "x-systemd.mount-timeout=10s"
            "_netdev"
            "noauto"
            "user"
            "users"
            "vers=3.1.1"
            "iocharset=utf8"
            "echo_interval=30"
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
            options = [
                "defaults,mode=777,size=100%,noatime"
                "noswap"
            ];
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
        #includeDefaultModules = false;
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
