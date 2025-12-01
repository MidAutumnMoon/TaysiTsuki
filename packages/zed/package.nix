{
    lib,
    stdenv,
    tsuki,
    autoPatchelfHook,

    libbsd,
    alsa-lib,
    xorg,
    libxkbcommon,
    wayland,
    vulkan-loader,
    zlib,
    glibc,

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
    version = "0.214.7";

    src = tsuki.fetchGitHubRelease {
        owner = "zed-industries";
        repo = "zed";
        tag = "v${version}";
        file = "zed-linux-x86_64.tar.gz";
        hash = "sha256-GoUONEjtp5zc6NiAdg4+rnJIZLJHauaR3WX1ycuUe5U=";
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
        xorg.libX11
        xorg.libxcb
        zlib
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
