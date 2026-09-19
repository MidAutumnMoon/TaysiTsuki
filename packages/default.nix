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

    # First-party crates of the Rust workspace; see ../rust.
    rustApps = import ../rust { inherit lib callPackage; };

in rec {

    tsuki = discovered // rustApps // {

        # test builds
        portableTest = callPackage ./portable/test.nix {};

        kde = callPackage ./kde/package.nix {
            kdePackages = prev.kdePackages;
        };
    };

    inherit (pkgsFrom "sops-nix")
        sops-install-secrets
    ;

    inherit (discovered.__pin)
        omp
        zcode
    ;

    linuxCachyos = tsuki.cachyos.linuxPackages;

    # tangled = {
    #     inherit (pkgsFrom "tangled")
    #         knot
    #     ;
    # };

    dnscrypt-proxy = tsuki.dnscrypt;

    obsidian = lib.useElectronBin prev prev.obsidian;

    yt-dlp = prev.yt-dlp.override {
        jsRuntime = prev.nodejs;
    };

    zram-generator =
        lib.onceride prev.zram-generator
        { rustPlatform = tsuki.rust; }
        { doCheck = false; }; # tests fail on github workflow

    sudo-rs =
        lib.onceride prev.sudo-rs
        { rustPlatform = tsuki.rust; }
        { doCheck = false; }; # tests fail on github workflow

    kdePackages = tsuki.kde;

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

    nix-direnv =
        prev.nix-direnv.override { nix = final.lix; };

}
