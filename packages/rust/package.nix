{
    flakes,
    callPackage,
    buildPackages,
    makeRustPlatform,
}:

let

    mkToolchain = channel: extensions:
        let inherit ( flakes.rust-overlay.lib ) mkRustBin ; in
        let bin = mkRustBin {} buildPackages; in
        bin.${channel}.latest.default.override {
            inherit extensions;
        };

    toolchain = mkToolchain "stable" [];

    toolchainForDev =
        mkToolchain "stable" [
            "rust-src"
            "llvm-tools-preview"
        ];

    platform = makeRustPlatform {
        rustc = toolchain;
        cargo = toolchain;
    };


in

platform // {

    inherit
        toolchain toolchainForDev
    ;

    rust-analyzer = callPackage ./rust-analyzer.nix {};

}
