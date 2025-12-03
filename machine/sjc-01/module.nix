{ lib, modulesPath, ... }:

{

    imports = [
        (modulesPath + "/profiles/qemu-guest.nix")
        ./filesystem.nix
    ];

    fonts.fontconfig.enable = false;
    documentation.man.enable = false;

    boot.machineId = "1c8811b2d97d4d8191354118fb3bc8b2";
    system.etc.overlay.mutable = lib.mkForce true;


}
