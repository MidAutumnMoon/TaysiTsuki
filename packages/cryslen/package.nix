{
    lib,
    stdenv,
    fetchFromGitHub,
    autoPatchelfHook,

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
    version = "0-unstable-2026-11-06";

    src = fetchFromGitHub {
        owner = "MidAutumnMoon";
        repo = "cryslen";
        rev = "8e66691f8de517b742c5c4ae3882a2f79c1d65f7";
        hash = "sha256-vJXEIg2ILoPJb4AxzgSg0kJcbiTfPuLd2uZojjuvC5Q=";
    };

    cargoHash = "sha256-Vem5JK1Rucm/7d6uNdSMRazWMNpUZh6f9J42dQrNASs=";

    doCheck = false;

    dontUseNinjaBuild = true;
    dontUseNinjaInstall = true;

    nativeBuildInputs = [
        autoPatchelfHook
        cmake
        meson
        ninja
        nasm
    ];

    buildInputs = [
        (lib.getLib stdenv.cc.cc)
    ];

    # dlopen:
    # winit → wayland, gl etc.
    # egui_system_font_provider → fontconfig
    runtimeDependencies = map lib.getLib [
        wayland
        libxkbcommon
        libglvnd
        fontconfig
    ];

    postInstall = /*sh*/ ''
        install -Dm644 assets/cryslen.desktop -t $out/share/applications
        mkdir -p $out/share/icons
        cp -r assets/icons/hicolor $out/share/icons/
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
