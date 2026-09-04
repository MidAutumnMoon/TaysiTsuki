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
    version = "0.115.1";

    src = fetchFromGitHub {
        owner = "nushell";
        repo = "nushell";
        tag = drvSelf.version;
        hash = "sha256-qndvtW1yD4n++LpGp+ucQVNqIm8jgcrM3M4O5q5WDgk=";
    };

    cargoHash = "sha256-73JFGry/aVBwIAs5DTqx7GbeCfwIopEIZ8pQp75TRq4=";

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
