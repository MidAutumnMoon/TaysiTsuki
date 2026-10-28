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
    version = "0-unstable-2026-10-28";

    src = fetchFromGitHub {
        owner = "MidAutumnMoon";
        repo = "cryslen";
        rev = "5517b647a675cf65a54f28d9b0ea7feeddc34665";
        hash = "sha256-rj/tnMfdaNJ9wuNloUumv7CMZoEVvnhMjNg2XFPu/ao=";
    };

    cargoHash = "sha256-QJjUW8uTSXfo32zDNPasiB0fTXf80nlHxtt3FHgjBEk=";

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
