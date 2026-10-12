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
    version = "0-unstable-2026-10-12";

    src = fetchFromGitHub {
        owner = "MidAutumnMoon";
        repo = "InOri";
        rev = "d79fb55e4cc8ecf4b3ad80370cd5553169d0f5c5";
        hash = "sha256-5lY8aqUb1XyijVBRg9/QcPTaF+rSLM3jgQ7W7N3Uy7M=";
    };

    cargoHash = "sha256-P4gjMYKafw/HxaUHe2r79isbavKlz5/q3rW3q8Gl3+Y=";

    outputs = [
        "out"
        "agentcept"
    ];

    doCheck = false;

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
            pythonVersions =
                [ "2" "2.7" "3" ]
                ++ map (minor: "3.${toString minor}") (lib.range 0 99);
            agentceptAliases =
                [ "find" "grep" "egrep" "fgrep" "python" "pip" ]
                ++ lib.concatMap
                    (version: [ "python${version}" "pip${version}" ])
                    pythonVersions;
        in /* sh */ ''
            mkdir -p "$agentcept/bin"
            mv "$out/bin/agentcept" "$agentcept/bin/"
            for name in ${lib.escapeShellArgs agentceptAliases}
            do
                ln -s agentcept "$agentcept/bin/$name"
            done

            makeBinaryWrapper "$out/bin/derputils" "$out/bin/,?" \
                --add-flag hops

            rm -v "$out/bin/xsleep"
            rm -v "$out/bin/xecho"

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
