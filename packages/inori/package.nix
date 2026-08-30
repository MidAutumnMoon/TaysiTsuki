{
    lib,
    stdenv,
    fetchFromGitHub,
    installShellFiles,

    tsuki,
    libjxl,
    imagemagick,
    libavif,
}:

tsuki.rust.buildRustPackage {

    pname = "inori";
    version = "0-unstable-2026-08-29";

    src = fetchFromGitHub {
        owner = "MidAutumnMoon";
        repo = "InOri";
        rev = "8cec59ee5fb30948d38bab907a0f22877e19f453";
        hash = "sha256-5Pw4n3H41E4OhVr4UY29hYmNKPrrhxKSyEUG1BBILZo=";
    };

    cargoHash = "sha256-Fygc0B6wbHpCy4ehIP20cGFUceb9lXpZKtO4s4Vb0dI=";

    doCheck = false;

    outputs = [
        "out"
        "lny"
    ];

    nativeBuildInputs = [
        installShellFiles
    ];

    env.CFG_CJXL_PATH = lib.getExe' libjxl "cjxl";
    env.CFG_AVIFENC_PATH = lib.getExe' libavif "avifenc";
    env.CFG_MAGICK_PATH = lib.getExe' imagemagick "magick";

    RUSTFLAGS = with stdenv;
        lib.optional hostPlatform.isx86_64 "-Ctarget-cpu=x86-64-v2"
    ;

    postFixup = /*sh*/ ''
        # coruma
        ln -sv "$out/bin/coruma-reverse" "$out/bin/,?"

        # lny
        declare -r LNY_BIN_DIR="$lny/bin"
        mkdir -pv "$LNY_BIN_DIR"
        mv -v "$out/bin/lny" -t "$LNY_BIN_DIR"
    '';

    postInstall =
        let
            canExe = with stdenv;
                buildPlatform.canExecute hostPlatform;
        in ''
            rm -v "$out/bin/xsleep"
            rm -v "$out/bin/xecho"
        '' + (lib.optionalString canExe ''
            bin="$out/bin/i"
            installShellCompletion --cmd i \
                --bash <("$bin" gen-complete -s bash) \
                --fish <("$bin" gen-complete -s fish) \
                --zsh <("$bin" gen-complete -s zsh)
        '');

    meta = {
        homepage = "https://github.com/MidAutumnMoon/InOri";
        license = lib.licenses.gpl3Plus;
    };

}
