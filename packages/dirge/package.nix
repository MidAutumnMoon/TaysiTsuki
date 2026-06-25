{
    lib,
    fetchFromGitHub,

    tsuki,
    pkg-config,
    openssl,
}:

tsuki.rust.buildRustPackage rec {

    pname = "dirge";
    version = "0.12.3";

    src = fetchFromGitHub {
        owner = "dirge-code";
        repo = "dirge";
        tag = "v${version}";
        hash = "sha256-yiuRLoDhk/CvpHLVZzst8gL1ceK153q5GKwsCAniw70=";
    };

    cargoHash = "sha256-dEOgKdsvfFo08HnkE9ptPp+VAwRrMo83OBvypVAUGGk=";

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
