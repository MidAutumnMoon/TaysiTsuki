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
    version = "0-unstable-2026-10-20";

    src = fetchFromGitHub {
        owner = "MidAutumnMoon";
        repo = "cryslen";
        rev = "a7b66bee8caaf21fc5da0efe0483d0b69bfe0ddf";
        hash = "sha256-dMtN5CghCSHuuxOeKD53laJt4RnFEK3SFVglfjIF7dA=";
    };

    cargoHash = "sha256-N/mFNCcadUlGZPEQr66BQQkEETpDVDqHg2xD0CHVs24=";

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
