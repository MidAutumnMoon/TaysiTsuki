{ modulesPath, ... }:

{

    imports = [
        (modulesPath + "/profiles/qemu-guest.nix")
        ./filesystem.nix
    ];

    fonts.fontconfig.enable = false;
    documentation.man.enable = false;

    boot.machineId = "76b74e865ccb465e97070c85bf39b1c2";

}
