# Upstream binary on the host's nix-ld shim (programs.nix-ld, ren
# only); its NEEDEDs are glibc-only. Not nixpkgs' from-source omp: this
# tracks upstream releases, with tests.run enforcing the loader contract.
{
    lib,
    stdenvNoCC,
    glibc,
    makeBinaryWrapper,
    runCommand,
    tsuki,
}:

stdenvNoCC.mkDerivation (drvSelf: {
    pname = "omp";
    version = "18.4.3";

    src = tsuki.fetchGitHubRelease {
        owner = "can1357";
        repo = "oh-my-pi";
        tag = "v${drvSelf.version}";
        file = "omp-linux-x64";
        hash = "sha256-r87N/x9CHzyI+xcUxAezcAiZtN4+0APNg2n1KubKh94=";
    };

    dontUnpack = true;
    # patchelf/strip corrupt bun-compiled ELFs.
    dontPatchELF = true;
    dontStrip = true;

    nativeBuildInputs = [ makeBinaryWrapper ];

    installPhase = /* sh */ ''
        runHook preInstall
        install -Dm555 $src $out/libexec/omp/omp
        makeBinaryWrapper $out/libexec/omp/omp $out/bin/omp \
            --set NIX_LD "${lib.getLib glibc}/lib/ld-linux-x86-64.so.2" \
            --set PI_SKIP_VERSION_CHECK 1
        runHook postInstall
    '';

    # Tracked binary, no link-time checks — glibc drift would surface
    # only at exec. The loader is invoked directly: the shim is a host
    # activation, absent from build sandboxes.
    passthru.tests.run = runCommand "omp-run-check" { } /* sh */ ''
        ${lib.getLib glibc}/lib/ld-linux-x86-64.so.2 \
            ${drvSelf.finalPackage}/libexec/omp/omp --version >/dev/null
        touch $out
    '';

    meta = {
        description = "oh-my-pi terminal coding agent (upstream binary)";
        mainProgram = "omp";
        platforms = [ "x86_64-linux" ];
    };
})
