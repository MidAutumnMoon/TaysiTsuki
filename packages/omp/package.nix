# Upstream binary on the host's nix-ld shim (programs.nix-ld, ren
# only); its NEEDEDs are glibc-only. Not nixpkgs' from-source omp: this
# tracks upstream releases, with tests.run enforcing the loader contract.
#
# The bash tool runs inside omp's embedded brush shell, where find/grep
# (and the rest of the uutils builtins) are in-process builtins shadowing
# $PATH; they must be off for the agentcept prefix below to be reached at
# all. --set-default keeps `PI_DISABLE_UUTILS_BUILTINS=0 omp` as an
# escape hatch. Caveat: omp's shell snapshot re-exports PATH after
# sourcing the user's rc — an rc that reorders PATH silently demotes the
# prefix.
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
    version = "18.4.8";

    src = tsuki.fetchGitHubRelease {
        owner = "can1357";
        repo = "oh-my-pi";
        tag = "v${drvSelf.version}";
        file = "omp-linux-x64";
        hash = "sha256-G4j3oNo/Ye3akV2DbhH2PyDytWrqwt36Ts4PqnJvMcI=";
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
            --set PI_SKIP_VERSION_CHECK 1 \
            --set-default PI_DISABLE_UUTILS_BUILTINS 1 \
            --prefix PATH : "${tsuki.inori.agentcept}/bin"
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
