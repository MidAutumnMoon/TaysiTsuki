{
    lib,
    stdenv,
    pkgsStatic,

    fetchFromGitHub,
}:

pkgsStatic.tsuki.rust.buildRustPackage rec {

    pname = "shadowsocks-rust";
    version = "1.25.0";

    src = fetchFromGitHub {
        owner = "shadowsocks";
        repo = "shadowsocks-rust";
        tag = "v${version}";
        hash = "sha256-BS6tc/ac7zewfzYvGWf+OkYjNjBwOWYTumVtQpjWHdg=";
    };

    cargoHash = "sha256-Qx5l6LC2KBLX9I4R/spZyPo61GzDilkgH5LBjGgVCFA=";

    doCheck = false;

    RUSTFLAGS = with stdenv;
        lib.optional hostPlatform.isx86_64 "-Ctarget-cpu=x86-64-v3"
    ;

    env.CARGO_PROFILE_RELEASE_LTO = "thin";
    env.CARGO_PROFILE_RELEASE_CODEGEN_UNITS = "16";

    buildNoDefaultFeatures = true;

    buildFeatures = [
        # "service"
        "server"
        # "hickory-dns"
        # "local-http"
        "multi-threaded"
        "aead-cipher-2022"
        "logging"
        "security-replay-attack-detect"
        "mimalloc"
    ];

    meta = {
        homepage = "https://github.com/shadowsocks/shadowsocks-rust";
        license = lib.licenses.mit;
    };

}

