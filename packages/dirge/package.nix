{
    lib,
    fetchFromGitHub,

    tsuki,
    pkg-config,
    openssl,
}:

tsuki.rust.buildRustPackage rec {

    pname = "dirge";
    version = "0.8.1";

    src = fetchFromGitHub {
        owner = "dirge-code";
        repo = "dirge";
        tag = "v${version}";
        hash = "sha256-PTlleCz6nDwKJ4BZYh9a1dibLn98d2hVVm/4XQpJOM4=";
    };

    cargoHash = "sha256-pBhsnIeF7/a2WrxBsGIpk/gnB+ff9quxXCM427L4Nio=";

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
