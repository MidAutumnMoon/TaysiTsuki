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
    version = "0-unstable-2026-05-11";

    src = fetchFromGitHub {
        owner = "MidAutumnMoon";
        repo = "InOri";
        rev = "b306286c9e36762910b8dd13ca562c3f20f84418";
        hash = "sha256-wtIEKrQz6oitj1taKjnhrFOVNWEQ3TWZM+PnU7wqvWs=";
    };

    cargoHash = "sha256-MFLSWY241VK1SLFV25vbSjFZ25aZqlqzwbr8JWJOtQk=";

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
        in lib.optionalString canExe ''
            bin="$out/bin/i"
            installShellCompletion --cmd i \
                --bash <("$bin" gen-complete -s bash) \
                --fish <("$bin" gen-complete -s fish) \
                --zsh <("$bin" gen-complete -s zsh)
        '';

    meta = {
        homepage = "https://github.com/MidAutumnMoon/InOri";
        license = lib.licenses.gpl3Plus;
    };

}
