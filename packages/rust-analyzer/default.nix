{
    lib,
    stdenv,
    fetchFromGitHub,

    rustTeapot,
}:

rustTeapot.buildRustPackage rec {

    pname = "rust-analyzer";
    version = "2025-04-07";

    src = fetchFromGitHub {
        owner = "rust-lang";
        repo = pname;
        tag = version;
        hash = "sha256-3lJ0W+mzfuR5FZM7JS7EfCJ5wBhu44fRBFu2/gKORzc=";
    };

    cargoHash = "sha256-sOuswCnF5y/L8x586PpcrLQj19+5x8COi9xBE2SRLYY=";
    useFetchCargoVendor = true;

    doCheck = false;

    cargoBuildFlags = [
        "--bin=rust-analyzer"
    ];

    buildFeatures = [
        "jemalloc"
    ];

    env.CFG_RELEASE = version;
    env.CARGO_PROFILE_RELEASE_LTO = "thin";
    env.CARGO_PROFILE_RELEASE_STRIP = "debuginfo";

    RUSTFLAGS = with stdenv;
        lib.optional hostPlatform.isx86_64 "-Ctarget-cpu=x86-64-v3"
    ;

    meta = with lib; {
        homepage = "https://rust-analyzer.github.io";
        license = with licenses; [ mit asl20 ];
        mainProgram = pname;
    };
}
