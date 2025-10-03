{ lib, config, pkgs, ... }:

let

    inherit ( config )
        lore
    ;

in

{

    imports = [
        ./services/samba.nix
    ];

    networking = {
        hostName = lore.machines.phia.hostname;
        hostId = "0a3e0a19";
        proxy.default =
            "http://${lore.apps.homelab.proxy.fqdn}:${toString lore.ports.proxy}";
        useDHCP = false;
        tempAddresses = "disabled";
    };

    systemd.network.networks = {
        "10-enp2s0" = {
            name = "enp2s0";
            DHCP = "yes";
            networkConfig = {
                MulticastDNS = "resolve";
                DNSSEC = "no";
            };
        };
    };

    services.caddy.enable = true;

    environment.systemPackages = with pkgs; [
        fastfetchMinimal
        hdparm
        ncdu
        rclone
        smartmontools
        fuc
    ];

    security.sudo.wheelNeedsPassword = false;

    # Avoid using nobody
    users.users."fileshare" = {
        isNormalUser = true;
        # better come up with another way to handle samba share
        # filesystem permission ...
        extraGroups = [ "wheel" ];
        openssh.authorizedKeys.keys = [ config.lore.pubkeys.teapot ];
    };

    fonts.fontconfig.enable = false;

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

