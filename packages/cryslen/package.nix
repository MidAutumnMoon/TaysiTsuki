{
    lib,
    stdenv,
    fetchFromGitHub,
    makeBinaryWrapper,

    tsuki,
    cmake,
    meson,
    ninja,
    nasm,
    wayland,
    libxkbcommon,
    libglvnd,
    fontconfig,
}:

tsuki.rust.buildRustPackage {

    pname = "cryslen";
    version = "0-unstable-2026-10-30";

    src = fetchFromGitHub {
        owner = "MidAutumnMoon";
        repo = "cryslen";
        rev = "20841fafad4bc7d914b6c24ddb3a782b01b4d7fb";
        hash = "sha256-hRx4kmv94Zi5tnkUqlUHLlV2Sydk8GH/S9XwNffBm18=";
    };

    cargoHash = "sha256-Yt+Ya8yXGDsHup3W64dUDerVsEj3dp0/7+ksMfk5rYs=";

    doCheck = false;

    dontUseNinjaBuild = true;
    dontUseNinjaInstall = true;

    nativeBuildInputs = [
        cmake
        meson
        ninja
        nasm
        makeBinaryWrapper
    ];

    # winit → wayland, gl etc.
    # egui_system_font_provider → fontconfig
    postInstall = /*sh*/ ''
        install -Dm644 assets/cryslen.desktop -t $out/share/applications
        mkdir -p $out/share/icons
        cp -r assets/icons/hicolor $out/share/icons/

        wrapProgram $out/bin/cy \
            --suffix LD_LIBRARY_PATH : ${lib.makeLibraryPath [
                wayland
                libxkbcommon
                libglvnd
                fontconfig
            ]}
    '';

    RUSTFLAGS = with stdenv;
        lib.optional hostPlatform.isx86_64 "-Ctarget-cpu=x86-64-v3"
    ;

    meta = {
        homepage = "https://github.com/MidAutumnMoon/cryslen";
        mainProgram = "cy";
        platforms = lib.platforms.linux;
        # no license file upstream
        license = lib.licenses.unfree;
    };

}
