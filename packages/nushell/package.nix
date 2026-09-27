{
    lib,
    fetchFromGitHub,
    zstd,
    pkg-config,
    tsuki,
    stdenv,
}:

tsuki.rust.buildRustPackage (drvSelf: {
    pname = "nushell";
    version = "0.116.0";

    src = fetchFromGitHub {
        owner = "nushell";
        repo = "nushell";
        tag = drvSelf.version;
        hash = "sha256-xSV4v7VJ3vd39a4hAywjo7hXtwrB598DtMOsYWqfIFA=";
    };

    cargoHash = "sha256-SL+ARL+fFFy8R3IW6IYPcbS+mAXb+Mzp4v3y5uv7wAI=";

    nativeBuildInputs = [
        pkg-config
    ];

    buildInputs = [
        zstd
    ];

    RUSTFLAGS = with stdenv;
        lib.optional hostPlatform.isx86_64 "-Ctarget-cpu=x86-64-v3";

    buildNoDefaultFeatures = true;
    buildFeatures = [
        "network"
        "rustls-tls"
        # "sqlite"
        "lsp"
    ];

    doCheck = false;

    meta = {
        description = "Modern shell written in Rust";
        homepage = "https://www.nushell.sh/";
        license = lib.licenses.mit;
        mainProgram = "nu";
    };
})
