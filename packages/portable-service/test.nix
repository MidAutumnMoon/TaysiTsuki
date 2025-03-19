let flake = builtins.getFlake ( toString ../.. ); in
let pkgs = flake.pkgsBrew.pkgsOf "x86_64-linux"; in

pkgs.callPackage (

{
    hello,
    makePortableServices,
    writeText,
}:

let

    unitA = writeText "example-unita" ''
        fake unit
    '';

in

makePortableServices {
    name = "example";
    version = "dev";

    units = [ unitA ];

    symlinks = [
        { src = "${hello}/bin/hello"; dst = "/hello"; }
    ];

    allowImpure = true;
}

) {}
