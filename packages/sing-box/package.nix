{
    lib,
    stdenv,
    tsuki,
    installShellFiles,
    autoPatchelfHook,
}:

stdenv.mkDerivation (drvSelf: {

    pname = "sing-box";
    version = "1.13.7";

    src = tsuki.fetchGitHubRelease {
        owner = "SagerNet";
        repo = "sing-box";
        tag = "v${drvSelf.version}";
        file = "sing-box-${drvSelf.version}-linux-amd64-musl.tar.gz";
        hash = "sha256-qB5h68LfiknrC44NSl41ddS04y3mBnBNAFaHuwZS9Ic=";
    };

    nativeBuildInputs = [
        installShellFiles
        autoPatchelfHook
    ];

    installPhase =
        let
            canExe = with stdenv;
                buildPlatform.canExecute hostPlatform;
        in ''
            mkdir -p "$out"
            install -Dm755 "sing-box" "$out/bin/sing-box"
        '' + lib.optionalString canExe ''
            bin="$out/bin/sing-box"
            installShellCompletion --cmd sing-box \
                --bash <("$bin" completion bash) \
                --fish <("$bin" completion fish) \
                --zsh <("$bin" completion zsh)
        '';

    meta = {
        homepage = "https://sing-box.sagernet.org";
        description = "Universal proxy platform";
        license = lib.licenses.gpl3Plus;
        mainProgram = "sing-box";
    };

})
