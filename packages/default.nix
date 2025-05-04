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

in {

    tsuki = discovered // reexported // {};

    inherit ( pkgsFrom "sops-nix" )
        sops-install-secrets
    ;

    inherit ( pkgsFrom "colmena" )
        colmena
    ;

    makePortableService = discovered.portable-service;

    zram-generator =
        prev.zram-generator.overrideAttrs { doCheck = false; };

}
