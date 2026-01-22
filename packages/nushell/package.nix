{
    lib,
    fetchFromGitHub,
    zstd,
    pkg-config,
    tsuki,
}:

tsuki.rust.buildRustPackage (drvSelf: {
    pname = "nushell";
    version = "0.110.0";

    src = fetchFromGitHub {
        owner = "nushell";
        repo = "nushell";
        tag = drvSelf.version;
        hash = "sha256-iytTJZ70kg2Huwj/BSwDX4h9DVDTlJR2gEHAB2pGn/k=";
    };

    cargoHash = "sha256-a/N0a9ZVqXAjAl5Z7BdEsIp0He3h0S/owS0spEPb3KI=";

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
