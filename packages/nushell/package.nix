{
    lib,
    fetchFromGitHub,
    zstd,
    pkg-config,
    tsuki,
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

    buildNoDefaultFeatures = true;
    buildFeatures = [
        "network"
        "rustls-tls"
        "sqlite"
    ];

    doCheck = false;

    meta = {
        description = "Modern shell written in Rust";
        homepage = "https://www.nushell.sh/";
        license = lib.licenses.mit;
        mainProgram = "nu";
    };
})
