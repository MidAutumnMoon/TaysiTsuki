{ lib, flakes }:

final: prev:

let

    callPackage = final.newScope {
        inherit lib;
    };

    pkgsFrom =
        name: flakes.${name}.packages.${final.system};

    discovered =
        lib.packagesFromDirectoryRecursive {
            inherit callPackage;
            directory = ./.;
        };

    reexported = {
    };

in rec {

    tsuki = discovered // reexported // {};

    inherit ( pkgsFrom "sops-nix" )
        sops-install-secrets
    ;

    inherit ( pkgsFrom "colmena" )
        colmena
    ;

    /*
     * Web facing services and other network
     * related things.
     */

    shadowsocks_teapot =
        callPackage ./shadowsocks {};

    hysteria_teapot =
        callPackage ./hysteria {};

    mihomo =
        callPackage ./mihomo {};

    /*
     * Terminals, shells and other things used in
     * that environment like CLI/TUI tools or multiplexers.
     *
     * Basically everything in Linux uh?
     */

    inori =
        callPackage ./inori {};

    fishPlugins =
        callPackage ./fish/plugins { old = prev.fishPlugins; };

    neovim_teapot =
        callPackage ./neovim {};

    prime-offload =
        callPackage ./prime-offload {};

    /*
     * Desktop, GUI, graohics etc. things.
     *
     * Does terminal emulator belongs to this
     * category or the previous one? Hmmm...
     */

    firefox_teapot =
        callPackage ./firefox {};

    /*
     * Languages and their toolchinas>
     */

    ruby_teapot =
        callPackage ./ruby {};

    rust-analyzer_teapot =
        callPackage ./rust-analyzer {};

    /*
     * Things that no clear category they are
     * falling into.
     */

    prvn-pkgs =
        callPackage ./prvn-pkgs {};

    metacubexd =
        callPackage ./metacubexd {};

    makePortableServices =
        callPackage ./portable-service {};

    vuetorrent_teapot =
        callPackage ./vuetorrent {};

    zram-generator =
        prev.zram-generator.overrideAttrs { doCheck = false; };

    writers = callPackage ./writers { inherit ( prev ) writers; };

    /*
     * Optimization flags. Mostly unused.
     */

    teapot.march = "x86-64-v3";

    teapot.mtune = "znver2";

    teapot.optimiz = [
        "-O3"
        "-march=${teapot.march}"
        "-mtune=${teapot.mtune}"
        "-mpclmul"
        "-pipe"
    ];

    teapot.RUSTFLAGS = [
        "-Ctarget-cpu=${teapot.march}"
    ];


    /*
     * Rust toolchains
     */

    rustToolchainTeapot =
        let inherit ( flakes.rust-overlay.lib ) mkRustBin ; in
        let rsbin = mkRustBin {} final.buildPackages; in
        rsbin.stable.latest.default.override {
            extensions = [ "rust-src" ];
        }
    ;

    rustTeapot = with final; makeRustPlatform rec {
        rustc = rustToolchainTeapot;
        cargo = rustc;
    };

    # "mkDerivationFromStdenv" is a function which accepts a stdenv
    # as argument and returns the well-known "mkDerivation" function,
    # the default and probably only impl is make-derivation.nix
    #
    # By wrapping "mkDerivationFromStdenv" any derivation can
    # be modified using a custom $functor just before being given birth.
    #
    # $functor is used to overrideAttrs on derivations
    # $stdenv is some normal stdenv, don't forget this function is
    #         a mimic of "mkDerivationFromStdenv" whose
    #         argument is stdenv
    # $mkDrvArgs: after accepting $stdenv the result is just
    #             a "mkDerivation" function, this is its argument
    defaultMkDrvImpl = with final;
        import "${path}/pkgs/stdenv/generic/make-derivation.nix" {
            inherit lib config;
        };

    overridableMkDrvImpl = mkDrvImpl: functor:
        ( stdenv: mkDrvArgs:
          ( ( mkDrvImpl stdenv ) mkDrvArgs ).overrideAttrs functor
        );

    overrideAttrsOnAllDrv = stdenv: functor:
        stdenv.override ( oldArgs: {
            mkDerivationFromStdenv = overridableMkDrvImpl
                ( oldArgs.mkDerivationFromStdenv or defaultMkDrvImpl )
                functor;
        } );

    # demo
    useLLDLinker = stdenv:
        overrideAttrsOnAllDrv stdenv ( drvAttrs: {
            NIX_CFLAGS_LINK =
                toString ( drvAttrs.NIX_CFLAGS_LINK or "" )
                + " -fuse-ld=lld";
        } );

}
