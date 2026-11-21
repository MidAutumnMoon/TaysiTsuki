{
    lib,
    stdenv,
    fetchFromGitHub,
    installShellFiles,
    makeBinaryWrapper,

    tsuki,
    libjxl,
    imagemagick,
    libavif,
    ugrep,
}:

tsuki.rust.buildRustPackage {

    pname = "inori";
    version = "0-unstable-2026-11-21";

    src = fetchFromGitHub {
        owner = "MidAutumnMoon";
        repo = "InOri";
        rev = "8466b6fa954bc0afd9069623207ac37e6e1ac616";
        hash = "sha256-UlcpB0MqZXDA3yUFR9mZO8JH6Ko4/SoigYOs6DjIZWY=";
    };

    cargoHash = "sha256-CW3Wvo5U3gTA/ydR9NFVAA5gHDVBgllit0BHzZq/6m4=";

    doCheck = false;

    env.CARGO_PROFILE_RELEASE_LTO = "thin";

    nativeBuildInputs = [
        installShellFiles
        makeBinaryWrapper
    ];

    env.CFG_CJXL_PATH = lib.getExe' libjxl "cjxl";
    env.CFG_AVIFENC_PATH = lib.getExe' libavif "avifenc";
    env.CFG_MAGICK_PATH = lib.getExe' imagemagick "magick";
    env.CFG_UGREP_PATH = lib.getExe' ugrep "ugrep";

    RUSTFLAGS = with stdenv;
        lib.optional hostPlatform.isx86_64 "-Ctarget-cpu=x86-64-v3"
    ;

    postInstall =
        let
            canExe = with stdenv;
                buildPlatform.canExecute hostPlatform;
        in /* sh */ ''
            makeBinaryWrapper "$out/bin/derputils" "$out/bin/,?" \
                --add-flag hops

            ${lib.optionalString canExe ''
                bin="$out/bin/i"
                installShellCompletion --cmd i \
                    --bash <("$bin" completion bash) \
                    --fish <("$bin" completion fish) \
                    --zsh <("$bin" completion zsh)
            ''}
        '';

    meta = {
        homepage = "https://github.com/MidAutumnMoon/InOri";
        license = lib.licenses.gpl3Plus;
        outputsToInstall = [ "out" ];
    };

}
