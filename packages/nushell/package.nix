{
    lib,
    fetchFromGitHub,
    zstd,
    pkg-config,
    tsuki,
}:

tsuki.rust.buildRustPackage (drvSelf: {
    pname = "nushell";
    version = "0.113.1";

    src = fetchFromGitHub {
        owner = "nushell";
        repo = "nushell";
        tag = drvSelf.version;
        hash = "sha256-sV2fN9TOWQVyPVFSWdNLPOtOdLuynPTvt9+uqJsgtds=";
    };

    cargoHash = "sha256-yfJPhx+Y+Y3vkIQU/w3DCKJpH4LsEmzDzyEuyor5PDc=";

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
