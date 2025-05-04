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

        tsuki.rust-analyzer

        ruby_teapot.with_preferred_gems
        ruby_teapot.rubocop
        rustToolchainTeapot
        ( clang.override { inherit ( llvmPackages ) bintools; } )

        nixd
        colmena

        wsl-open

        tsuki.inori
        parinfer-rust # for the dylib
        skim

        deno
    ];

    sops.age.keyFile = "${configHome}/sops/age/keys.txt";

}
