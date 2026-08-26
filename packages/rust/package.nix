{
    flakes,
    callPackage,
    buildPackages,
    makeRustPlatform,
}:

let

    mkToolchain = channel: extensions: targets:
        let inherit (flakes.rust-overlay.lib) mkRustBin ; in
        let bin = mkRustBin {} buildPackages; in
        bin.${channel}.latest.minimal.override {
            inherit extensions targets;
        };

    toolchain = mkToolchain "stable"
        [ "clippy" ] [ ];

    toolchainForDev =
        mkToolchain "stable" [
            "rust-src"
            "rustfmt"
            "clippy"
        ] [
            # "wasm32-unknown-unknown"
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
