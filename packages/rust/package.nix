{
    flakes,
    callPackage,
    buildPackages,
    makeRustPlatform,
}:

let

    mkToolchain = channel: extensions: targets:
        let inherit ( flakes.rust-overlay.lib ) mkRustBin ; in
        let bin = mkRustBin {} buildPackages; in
        bin.${channel}.latest.default.override {
            inherit extensions targets;
        };

    toolchain = mkToolchain "stable"
        [] [ "wasm32-unknown-unknown" ];

    toolchainForDev =
        mkToolchain "stable" [
            "rust-src"
            "llvm-tools-preview"
        ] [
            "wasm32-unknown-unknown"
        ];

    platform = makeRustPlatform {
        rustc = toolchain;
        cargo = toolchain;
    };


in

platform // {

    inherit toolchain toolchainForDev;

    rust-analyzer = callPackage ./rust-analyzer.nix {};

}
