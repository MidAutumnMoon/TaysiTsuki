{
    lib,
    stdenv,
    tsuki,
    autoPatchelfHook,
    installShellFiles,
    unzip,
}:

stdenv.mkDerivation rec {

    pname = "deno";
    version = "2.6.10";

    src = tsuki.fetchGitHubRelease {
        owner = "denoland";
        repo = "deno";
        tag = "v${version}";
        file = "deno-x86_64-unknown-linux-gnu.zip";
        hash = "sha256-p8nVwfk7+qvgPDwFg6jIjK9pXbPOxN6ik4RAA4YJ8iU=";
    };

    nativeBuildInputs = [
        autoPatchelfHook
        unzip
        installShellFiles
    ];

    buildInputs = [
        stdenv.cc.libc
        stdenv.cc.cc
    ];

    strictDeps = true;

    unpackPhase = ''
        unzip "$src"
    '';

    installPhase =
        let
            canExe = with stdenv;
                buildPlatform.canExecute hostPlatform;
        in ''
            install -Dm755 deno "$out/bin/deno"
            autoPatchelf "$out/bin/deno"
        '' + lib.optionalString canExe ''
            bin="$out/bin/deno"
            installShellCompletion --cmd deno \
                --bash <("$bin" completions bash) \
                --fish <("$bin" completions fish) \
                --zsh <("$bin" completions zsh)
        '';

    meta = {
        description = "Binary Deno";
        mainProgram = "deno";
    };
}
