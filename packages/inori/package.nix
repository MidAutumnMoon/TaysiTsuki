{
    lib,
    stdenv,
    fetchFromGitHub,

    tsuki,

    libavif,
    libjxl,
    imagemagick,
}:

tsuki.rust.buildRustPackage {

    pname = "inori";
    version = "0-unstable-2025-05-19";

    src = fetchFromGitHub {
        owner = "MidAutumnMoon";
        repo = "InOri";
        rev = "175293904816fd83541a2d7c631728219da7dde1";
        hash = "sha256-Ofj5vBrl1FLAZL/jcZZrAb3g8xR+P4oiq4THGYlfn5s=";
    };

    cargoHash = "sha256-R2XCFREmwHXTpMiDbNRCJd3QrnlAWryppeMq804EmF8=";
    useFetchCargoVendor = true;

    env.CFG_CJXL_PATH = lib.getExe' libjxl "cjxl";
    env.CFG_AVIFENC_PATH = lib.getExe' libavif "avifenc";
    env.CFG_MAGICK_PATH = lib.getExe' imagemagick "magick";

    RUSTFLAGS = with stdenv;
        lib.optional hostPlatform.isx86_64 "-Ctarget-cpu=x86-64-v3"
    ;

    postInstall = ''
        ln -sv "$out/bin/coruma-reverse" "$out/bin/,?"
    '';

    meta = {
        homepage = "https://github.com/MidAutumnMoon/InOri";
        license = lib.licenses.gpl3Plus;
    };

}

