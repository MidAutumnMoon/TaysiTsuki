{
    lib,
    fetchFromGitHub,
    zstd,
    libgit2,
    pkg-config,
    tsuki,
    stdenv,
}:

tsuki.rust.buildRustPackage (drvSelf: {
    pname = "nushell";
    version = "0.117.0";

    src = fetchFromGitHub {
        owner = "nushell";
        repo = "nushell";
        tag = drvSelf.version;
        hash = "sha256-+lA9T0Wa/K50qCfyGFdNlEmCZWCeBk8KcxIvDCKk2no=";
    };

    cargoHash = "sha256-0t1ubpyPiXucUlJ+Nwu2u3LZ15GtX6mF2kMy9HkbClw=";

    nativeBuildInputs = [
        pkg-config
    ];

    buildInputs = [
        zstd
        libgit2
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
