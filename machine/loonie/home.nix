{ lib, config, pkgs, ... }:

let

    inherit ( config.xdg )
        configHome
    ;

in {

    imports = lib.listAllModules ../../dotfiles;

    home.packages = with pkgs; [
        sops
        rclone

        tsuki.rust.rust-analyzer

        tsuki.ruby.with_preferred_gems
        tsuki.ruby.rubocop
        tsuki.rust.toolchainForDev
        ( clang.override { inherit ( llvmPackages ) bintools; } )

        nixd
        colmena

        wsl-open

        tsuki.inori
        parinfer-rust # for the dylib
        skim

        deno
        fuc

        tsuki.opentofu
    ];

    sops.age.keyFile = "${configHome}/sops/age/keys.txt";

}
