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
    version = "0-unstable-2026-10-22";

    src = fetchFromGitHub {
        owner = "MidAutumnMoon";
        repo = "cryslen";
        rev = "f27ad40242f5349707d938ee0933ee36006c1511";
        hash = "sha256-61fED/8o9IskuyujXld+IqDQm+VSGYayeIXUnvYwDAI=";
    };

    cargoHash = "sha256-HU2NikzI68zi8dYzF8Oc37o7tzsJz0leHHvTCarRjII=";

    doCheck = false;

    # ninja's setup hook would claim buildPhase/installPhase before the
    # cargo hooks can set them, so the build would run plain ninja.
    dontUseNinjaBuild = true;
    dontUseNinjaInstall = true;

    # libavif-sys and libdav1d-sys compile vendored libavif+aom and dav1d
    # inside cargo build.
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
