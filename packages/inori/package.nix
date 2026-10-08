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
    version = "0-unstable-2026-10-08";

    src = fetchFromGitHub {
        owner = "MidAutumnMoon";
        repo = "InOri";
        rev = "cc6a872e54577b9e4be88a65582936c96a863da4";
        hash = "sha256-z+9MJh4ykMvYb5daE28+ojT1QuNXB8tYbnuAxIa7qJA=";
    };

    cargoHash = "sha256-azTfNOOM6DeUF8r3Xb/jeBHcGIFQBfLpin/pk1OZvms=";

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
