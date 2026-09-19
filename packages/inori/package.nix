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
    version = "0-unstable-2026-09-18";

    src = fetchFromGitHub {
        owner = "MidAutumnMoon";
        repo = "InOri";
        rev = "defcd3f0af8773c4045bd21f5fef2818edd15f93";
        hash = "sha256-UwCFHRIlV4fqHr8coD8jzRqkjIYAVQGP7Gek93UHMTE=";
    };

    cargoHash = "sha256-jrzy3eeDSMjZ8aT3Vk6B9Qswg/vHsHQRynK7L0LogjQ=";

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
