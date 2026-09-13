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
    version = "0-unstable-2026-09-13";

    src = fetchFromGitHub {
        owner = "MidAutumnMoon";
        repo = "InOri";
        rev = "b24182a33048ce30e581201e19b114c16bc0fd63";
        hash = "sha256-UXct4Ld6DhnmI1PB0aYBP6IiZQt/1Z85VjNa47FbFsk=";
    };

    cargoHash = "sha256-0m+R1uH6MHUqgw9ynlSchVIbGF/+jAYTLK9aMVxfahA=";

    doCheck = false;

    nativeBuildInputs = [
        installShellFiles
    ];

    env.CFG_CJXL_PATH = lib.getExe' libjxl "cjxl";
    env.CFG_AVIFENC_PATH = lib.getExe' libavif "avifenc";
    env.CFG_MAGICK_PATH = lib.getExe' imagemagick "magick";

    RUSTFLAGS = with stdenv;
        lib.optional hostPlatform.isx86_64 "-Ctarget-cpu=x86-64-v3"
    ;

    postFixup = /*sh*/ ''
    '';

    postInstall =
        let
            canExe = with stdenv;
                buildPlatform.canExecute hostPlatform;
        in ''
            ln -sv "$out/bin/derputils" "$out/bin/,?"

            rm -v "$out/bin/xsleep"
            rm -v "$out/bin/xecho"
        '' + (lib.optionalString canExe ''
            bin="$out/bin/i"
            installShellCompletion --cmd i \
                --bash <("$bin" completion bash) \
                --fish <("$bin" completion fish) \
                --zsh <("$bin" completion zsh)
        '');

    meta = {
        homepage = "https://github.com/MidAutumnMoon/InOri";
        license = lib.licenses.gpl3Plus;
    };

}
