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
    version = "0-unstable-2026-11-08";

    src = fetchFromGitHub {
        owner = "MidAutumnMoon";
        repo = "cryslen";
        rev = "1440f21e91e241ee4adbb60f86a552ea45b60f27";
        hash = "sha256-G/LB4uSgHOawf1r3t9FRZ5sNDUI6D2Onak33kWcAuW8=";
    };

    cargoHash = "sha256-evKxxybn29yXnpX6zQxuHWqFCLeQwRBrJZyLHurheMs=";

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
