{ lib, flakes }:

final: prev:

let

    callPackage = final.newScope {
        inherit lib flakes;
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

    makePortableService = discovered.portable-service;

    colmena =
        lib.onceride ( pkgsFrom "colmena" ).colmena
        # nix-eval-jobs from lix
        { nix-eval-jobs = final.nix-eval-jobs; }
        {};

    zram-generator =
        lib.onceride prev.zram-generator
        { rustPlatform = tsuki.rust; }
        { doCheck = false; }; # tests fail on github workflow

}
