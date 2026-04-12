{
    lib,
    fetchFromGitHub,
    zstd,
    pkg-config,
    tsuki,
}:

tsuki.rust.buildRustPackage (drvSelf: {
    pname = "nushell";
    version = "0.112.1";

    src = fetchFromGitHub {
        owner = "nushell";
        repo = "nushell";
        tag = drvSelf.version;
        hash = "sha256-y0EfP95XEVvse0xaSWK5Yr748tTVYRG7Bx+Qf5JrlYY=";
    };

    cargoHash = "sha256-Y/yaWj2akccehFVxrGHrsjzZd02L8qE9KoSSwzAeEwg=";

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
