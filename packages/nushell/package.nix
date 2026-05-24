{
    lib,
    fetchFromGitHub,
    zstd,
    pkg-config,
    tsuki,
}:

tsuki.rust.buildRustPackage (drvSelf: {
    pname = "nushell";
    version = "0.113.0";

    src = fetchFromGitHub {
        owner = "nushell";
        repo = "nushell";
        tag = drvSelf.version;
        hash = "sha256-qIiPEW2XO2gf9pMDHhGEvCfSU5iiOKMwi+9wAQEfjjw=";
    };

    cargoHash = "sha256-E7xO6oTw4uWh41g92AqkQ5iIr/uD6RCc2kBAYUP3Flg=";

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
