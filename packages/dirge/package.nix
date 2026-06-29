{
    lib,
    fetchFromGitHub,

    tsuki,
    pkg-config,
    openssl,
}:

tsuki.rust.buildRustPackage rec {

    pname = "dirge";
    version = "0.13.9";

    src = fetchFromGitHub {
        owner = "dirge-code";
        repo = "dirge";
        tag = "v${version}";
        hash = "sha256-w4do4h+4vtrlpeWJlF1X0lH+AhzBTkZpxjRvPmUszPs=";
    };

    cargoHash = "sha256-3YMzeWw1xsqIqBGjYF5CxhNZf/3/6QsMmlMk8foIe04=";

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
