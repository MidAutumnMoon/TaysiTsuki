{
    lib,
    fetchFromGitHub,

    tsuki,
    pkg-config,
    openssl,
}:

tsuki.rust.buildRustPackage rec {

    pname = "dirge";
    version = "0.11.0";

    src = fetchFromGitHub {
        owner = "dirge-code";
        repo = "dirge";
        tag = "v${version}";
        hash = "sha256-a8h1Rf6oid+Rl4y7U4cQAPp4jDJxgII9TX/XWun16DM=";
    };

    cargoHash = "sha256-Lxx5D6L3l5R6u5VFx3I23X5MbXgYpHhNrVSmf48/8/c=";

    nativeBuildInputs = [
        pkg-config
        tsuki.rust.bindgenHook
    ];

    buildInputs = [
        openssl
    ];

    doCheck = false;

    postPatch = ''
        # Upstream config forces clang + mold for incremental dev builds;
        # the Nix sandbox has a working linker already.
        rm -f .cargo/config.toml
    '';

    meta = {
        description = "Minimal, fast coding agent written in Rust";
        homepage = "https://github.com/dirge-code/dirge";
        license = lib.licenses.gpl3Only;
        mainProgram = "dirge";
    };
}
