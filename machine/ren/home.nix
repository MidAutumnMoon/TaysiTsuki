{ lib, config, pkgs, ... }:

let

    inherit ( config.xdg )
        configHome
    ;

in {

    imports = lib.listAllModules ../../dotfiles;

    home.packages = with pkgs; [
        atuin
        rclone

        tsuki.rust.rust-analyzer

        tsuki.rust.toolchainForDev
        ( clang.override { inherit ( llvmPackages ) bintools; } )

        nixd
        colmena

        fuc
    ];


    sops.age.keyFile = "${configHome}/sops/age/keys.txt";

}
