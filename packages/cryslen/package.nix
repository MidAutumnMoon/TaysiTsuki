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
    perl,
    pkg-config,
    wayland,
    libxkbcommon,
    libglvnd,
}:

tsuki.rust.buildRustPackage {

    pname = "cryslen";
    version = "0-unstable-2026-10-23";

    src = fetchFromGitHub {
        owner = "MidAutumnMoon";
        repo = "cryslen";
        rev = "801e8447d4296915659e3f4f4e3f09e99573837d";
        hash = "sha256-WgG9Nyj7I8VvfsYzGAdsDRHiTMty7Ol4Kj7U5c1iEic=";
    };

    cargoHash = "sha256-HU2NikzI68zi8dYzF8Oc37o7tzsJz0leHHvTCarRjII=";

    doCheck = false;

    dontUseNinjaBuild = true;
    dontUseNinjaInstall = true;

    nativeBuildInputs = [
        cmake
        meson
        ninja
        nasm
        perl
        pkg-config
        makeBinaryWrapper
    ];

    # winit/glutin dlopen libwayland-client, libwayland-egl, libxkbcommon
    # and libEGL at runtime. They never enter DT_NEEDED, so autoPatchelf
    # cannot provide them and the wrapper must.
    postInstall = /*sh*/ ''
        install -Dm644 assets/cryslen.desktop -t $out/share/applications
        mkdir -p $out/share/icons
        cp -r assets/icons/hicolor $out/share/icons/

        wrapProgram $out/bin/cy \
            --suffix LD_LIBRARY_PATH : ${lib.makeLibraryPath [
                wayland
                libxkbcommon
                libglvnd
            ]}
    '';

    RUSTFLAGS = with stdenv;
        lib.optional hostPlatform.isx86_64 "-Ctarget-cpu=x86-64-v3"
    ;

    meta = {
        description = "Minimal Wayland image and comic pager";
        homepage = "https://github.com/MidAutumnMoon/cryslen";
        mainProgram = "cy";
        platforms = lib.platforms.linux;
        # no license file upstream
        license = lib.licenses.unfree;
    };

}
