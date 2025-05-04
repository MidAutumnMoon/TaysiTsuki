{
    flakes,
    callPackage,
    buildPackages,
    makeRustPlatform,
}:

let

    # TODO: generalize this if necessary
    toolchain =
        let inherit ( flakes.rust-overlay.lib ) mkRustBin ; in
        let rsbin = mkRustBin {} buildPackages; in
        rsbin.stable.latest.default.override {
            extensions = [ "rust-src" ];
        };

    platform = makeRustPlatform {
        rustc = toolchain;
        cargo = toolchain;
    };

    rust-analyzer = callPackage ./rust-analyzer.nix {};

in

platform
// { inherit toolchain; }
// { inherit rust-analyzer; }
