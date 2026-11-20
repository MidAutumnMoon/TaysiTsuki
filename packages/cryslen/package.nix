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
    version = "0-unstable-2026-11-19";

    src = fetchFromGitHub {
        owner = "MidAutumnMoon";
        repo = "cryslen";
        rev = "19da399ac2461ae7eeb6b3c7330f2a894959d224";
        hash = "sha256-a0pNaFM2mkboAx/xgBvWaUafdLHcXdL0YTqmgjuIVk0=";
    };

    cargoHash = "sha256-zfHJa9WjjV3IiVGxbf77psuuRKeRsvid3bkSIJX2JGk=";

    doCheck = false;

    dontUseNinjaBuild = true;
    dontUseNinjaInstall = true;

    env.CARGO_PROFILE_RELEASE_LTO = "fat";
    env.CARGO_PROFILE_RELEASE_CODEGEN_UNITS = "1";

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
