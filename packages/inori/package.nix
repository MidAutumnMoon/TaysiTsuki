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
    version = "0-unstable-2026-09-17";

    src = fetchFromGitHub {
        owner = "MidAutumnMoon";
        repo = "InOri";
        rev = "6a67e1630af65c9576de1229690ad185f66be199";
        hash = "sha256-9tMwRZbe66odWqVYRQg/oxY/gihm4E5lrwTZqv4gnWk=";
    };

    cargoHash = "sha256-S9uuGWJG2GTQlN7xmBnQdi+Wg1KAa7GnmpyPbBnMRL8=";

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
