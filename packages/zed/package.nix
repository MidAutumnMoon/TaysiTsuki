{
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
}:

# Based on
# - zed-industries/zed : build.nix
# - nixpkgs zed
# - HPsaucii/zed-editor-flake
stdenv.mkDerivation rec {

    pname = "zed";
    version = "0.206.7";

    src = tsuki.fetchGitHubRelease {
        owner = "zed-industries";
        repo = "zed";
        tag = "v${version}";
        file = "zed-linux-x86_64.tar.gz";
        hash = "sha256-mPjTFIMAASXQCV36OyCXEvTDaEWMUX23WbzO6GmmixU=";
    };

    nativeBuildInputs = [
        autoPatchelfHook
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

    meta = {
        description = "Binary Zed Editor";
        mainProgram = "zed";
    };
}
