{ lib, flakes }:

final: prev:

let

    callPackage = final.newScope {
        inherit lib flakes;
    };

    hostSystem = final.stdenv.hostPlatform.system;

    pkgsFrom =
        name: flakes.${name}.packages.${hostSystem};

    legacyFrom =
        name: flakes.${name}.legacyPackages.${hostSystem};

    discovered =
        lib.packagesFromDirectoryRecursive {
            inherit callPackage;
            directory = ./.;
        };

in rec {

    tsuki = discovered // {
        # test builds
        localbinbox = callPackage ../home/localbinbox {};
        portableTest = callPackage ./portable/test.nix {};

        # rust workspace shortcuts
        workspace.src = flakes.self;
        workspace.cargoLock = {
            lockFile = ../Cargo.lock;
        };
    };

    inherit (pkgsFrom "sops-nix")
        sops-install-secrets
    ;

    bluesky-pds = prev.bluesky-pds.override {
        nodejs = prev.nodejs_22;
    };

    sillytavern = prev.sillytavern.override {
        buildNpmPackage = prev.buildNpmPackage.override {
            nodejs = prev.nodejs_22;
        };
    };

    # tangled = {
    #     inherit (pkgsFrom "tangled")
    #         knot
    #     ;
    # };

    dnscrypt-proxy = tsuki.dnscrypt;

    kdePackages = import ./plasma.nix lib prev;

    yt-dlp = prev.yt-dlp.override {
        inherit (tsuki) deno;
    };

    zram-generator =
        lib.onceride prev.zram-generator
        { rustPlatform = tsuki.rust; }
        { doCheck = false; }; # tests fail on github workflow

    sudo-rs =
        lib.onceride prev.sudo-rs
        { rustPlatform = tsuki.rust; }
        { doCheck = false; }; # tests fail on github workflow

    #
    # Lix overrides
    #

    lixSet = prev.lixPackageSets.latest;

    inherit (lixSet)
        lix
        # The default "lix" points to old stable version
        nix-eval-jobs
    ;

    nixVersions = prev.nixVersions // {
        stable = lixSet.lix;
        latest = lixSet.lix;
    };

    nixForLinking = prev.nixVersions.stable;

    # TODO: get rid of colmena flake
    colmena =
        (pkgsFrom "colmena").colmena.override {
            nix-eval-jobs = final.nix-eval-jobs;
            rustPlatform = final.tsuki.rust;
        };

    nix-direnv =
        prev.nix-direnv.override { nix = final.lix; };

}
