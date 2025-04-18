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

        rust-analyzer_teapot

        ruby_teapot.with_preferred_gems
        ruby_teapot.rubocop
        rustToolchainTeapot
        ( clang.override { inherit ( llvmPackages ) bintools; } )

        nixd
        colmena

        wsl-open

        inori
        parinfer-rust # for the dylib
        skim

        deno
    ];

    sops.age.keyFile = "${configHome}/sops/age/keys.txt";

}
