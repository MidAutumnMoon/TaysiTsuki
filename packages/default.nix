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

    tsuki = discovered // {};

    inherit ( pkgsFrom "sops-nix" )
        sops-install-secrets
    ;

    inherit (legacyFrom "nyx")
        linuxPackages_cachyos
        linuxPackages_cachyos-lts
    ;

    # tangled = {
    #     inherit (pkgsFrom "tangled")
    #         knot
    #     ;
    # };

    dnscrypt-proxy = tsuki.dnscrypt;

    yt-dlp = prev.yt-dlp.override {
        inherit (tsuki) deno;
    };

    zram-generator =
        lib.onceride prev.zram-generator
        { rustPlatform = tsuki.rust; }
        { doCheck = false; }; # tests fail on github workflow

    localbinbox = callPackage ../home/localbinbox {};
    portableTest = callPackage ./portable/test.nix {};

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

    colmena =
        ( pkgsFrom "colmena" ).colmena.override {
            nix-eval-jobs = final.nix-eval-jobs;
            rustPlatform = final.tsuki.rust;
        };

    nix-direnv =
        prev.nix-direnv.override { nix = final.lix; };

}
