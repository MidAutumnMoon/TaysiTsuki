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

    programs.fish = {

        interactiveShellInit = /* fish */ ''
            # Tell Windows Terminal to open new tabs with the same CWD
            function __windows_terminal --on-variable PWD
                set -q WT_SESSION
                and printf "\e]9;9;%s\e\\" ( wslpath -w "$PWD" )
            end
        '';

        # Stock "open" doesn't uses wsl-open, which makes it useless
        # on WSL.
        functions."open" = /* fish */ ''
            command wsl-open $argv
        '';

    };

}
