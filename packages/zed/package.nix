{
    lib,
    stdenv,
    tsuki,
    autoPatchelfHook,

    libbsd,
    alsa-lib,
    libxkbcommon,
    wayland,
    vulkan-loader,
    zlib,
    glibc,
    glib,
    libxcb,
    libX11,

    makeBinaryWrapper,
    nodejs,

    mimalloc,
}:

# Based on
# - zed-industries/zed : build.nix
# - nixpkgs zed
# - HPsaucii/zed-editor-flake
stdenv.mkDerivation rec {

    pname = "zed";
    version = "1.1.8";

    src = tsuki.fetchGitHubRelease {
        owner = "zed-industries";
        repo = "zed";
        tag = "v${version}";
        file = "zed-linux-x86_64.tar.gz";
        hash = "sha256-Xlc2NFFGJ5tj8tjXEe+k+m/ymbEqdc0ANEv4qfzMYgA=";
    };

    nativeBuildInputs = [
        autoPatchelfHook
        makeBinaryWrapper
    ];

    buildInputs = [
        stdenv.cc.libc
        stdenv.cc.cc
        libbsd
        alsa-lib
        libxkbcommon
        wayland
        libX11
        libxcb
        zlib
        glib
    ];

    runtimeDependencies = [
        glibc
        vulkan-loader
        wayland
    ];

    installPhase = ''
        mkdir -pv "$out"
        # remove bundled libs
        rm -r "lib"
        rm *.md
        mv -t "$out" *
        addAutoPatchelfSearchPath "$out/libexec"
    '';

    postFixup = ''
        for f in "$out/bin/zed" "$out/libexec/zed-editor"
        do
            wrapProgram "$f" \
                --inherit-argv0 \
                --suffix PATH : "${lib.makeBinPath [ nodejs ]}" \
                --set LD_PRELOAD "${mimalloc}/lib/libmimalloc.so"
        done
    '';

    meta = {
        description = "Binary Zed Editor";
        mainProgram = "zed";
    };
}
