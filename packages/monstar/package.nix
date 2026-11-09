{
    lib,
    stdenvNoCC,
    autoPatchelfHook,

    tsuki,
    glibc,
    wayland,
    fontconfig,
    freetype,
    harfbuzz,
    libxkbcommon,
    vulkan-loader,
}:

stdenvNoCC.mkDerivation (drvSelf: {

    pname = "monstar";
    version = "1.1.0";

    src = tsuki.fetchGitHubRelease {
        owner = "rockorager";
        repo = "monstar";
        tag = "v${drvSelf.version}";
        file = "monstar-${drvSelf.version}-x86_64-linux.tar.gz";
        hash = "sha256-Ocdgxj2Grh2Tw8NixChIH73RNgwmB7G8afES4RLUiuQ=";
    };

    nativeBuildInputs = [ autoPatchelfHook ];

    buildInputs = [
        glibc
        wayland
        fontconfig
        freetype
        harfbuzz
        libxkbcommon
    ];

    # The optional Vulkan renderer dlopens the loader.
    runtimeDependencies = [ vulkan-loader ];

    installPhase = /* sh */ ''
        mkdir -p "$out"
        cp -r . "$out"
    '';

    meta = {
        description = "Small Wayland terminal emulator";
        homepage = "https://github.com/rockorager/monstar";
        license = lib.licenses.mit;
        mainProgram = "monstar";
        platforms = [ "x86_64-linux" ];
    };

})