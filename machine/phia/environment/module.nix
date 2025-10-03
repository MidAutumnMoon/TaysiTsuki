{ pkgs, ... }:

let

    maintenance = pkgs.callPackage ./maintenance/package.nix {};

in

{

    environment.systemPackages = [
        maintenance
    ];

    passthru = {
        inherit maintenance;
    };

}
