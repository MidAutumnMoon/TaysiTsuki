{
    lib,
    fetchFromGitHub,

    tsuki,
    pkg-config,
    openssl,
}:

tsuki.rust.buildRustPackage rec {

    pname = "dirge";
    version = "0.12.4";

    src = fetchFromGitHub {
        owner = "dirge-code";
        repo = "dirge";
        tag = "v${version}";
        hash = "sha256-7gK1uz+NGtLEGCekDDE2w24ENJ5g/09fUA9zJInlqjQ=";
    };

    cargoHash = "sha256-J6QgaS3l+m8+k5hgPnOz9Sfk4LEass9vWjKRgOwbRCs=";

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
