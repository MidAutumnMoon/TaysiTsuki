{
    lib,
    stdenv,
    fetchFromGitHub,

    rustTeapot,
}:

rustTeapot.buildRustPackage rec {

    pname = "rust-analyzer";
    version = "2025-03-10";

    src = fetchFromGitHub {
        owner = "rust-lang";
        repo = pname;
        tag = version;
        hash = "sha256-MmYdZyVwKa3YHzqoHdHw9/jZXkDE/5M3M+7363t4Pkc=";
    };

    cargoHash = "sha256-t2cA2JWV+l2cfTUrIpPojNmrElVty2JJAi8+XdxquTs=";
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
