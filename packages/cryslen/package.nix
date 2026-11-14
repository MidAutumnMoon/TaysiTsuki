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
    version = "0-unstable-2026-11-13";

    src = fetchFromGitHub {
        owner = "MidAutumnMoon";
        repo = "cryslen";
        rev = "b496f3dfe611744c83fdf8acfa5c23be6501b458";
        hash = "sha256-spaJCSZNXUjZHK24sYzPj3uT5dTNLePave+tLXkxjZY=";
    };

    cargoHash = "sha256-iOjR6yhBJzI3Pgdq8CwCC2RUKMsf/+pwypfOApK6c2M=";

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
