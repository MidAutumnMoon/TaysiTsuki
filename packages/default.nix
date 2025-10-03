{ lib, flakes }:

final: prev:

let

    callPackage = final.newScope {
        inherit lib flakes;
    };

    pkgsFrom =
        name: flakes.${name}.packages.${final.system};

    legacyFrom =
        name: flakes.${name}.legacyPackages.${final.system};

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
        linuxPackages_cachyos-server
    ;

    dnscrypt-proxy = tsuki.dnscrypt;

    zram-generator =
        lib.onceride prev.zram-generator
        { rustPlatform = tsuki.rust; }
        { doCheck = false; }; # tests fail on github workflow

    #
    # Lix overrides
    #

    lixSet = prev.lixPackageSets.latest;

    inherit ( lixSet )
        # The default "lix" points to old stable version
        lix
        nix-eval-jobs
    ;

    nixVersions = prev.nixVersions // {
        stable = final.lixSet.lix;
        latest = final.lixSet.lix;
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
