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
    version = "0.116.1";

    src = fetchFromGitHub {
        owner = "nushell";
        repo = "nushell";
        tag = drvSelf.version;
        hash = "sha256-b62ICCP7Li88obcju4xBNVw7D+6TtRURrOUvzqcjHis=";
    };

    cargoHash = "sha256-+81FRwTlR5NSJuoaH7KCK6Qy1DiU5/JKNqfaAhZmMes=";

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
