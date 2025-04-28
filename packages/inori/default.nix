{
    lib,
    stdenv,
    fetchFromGitHub,

    rustTeapot,

    libavif,
    libjxl,
    imagemagick,
}:

rustTeapot.buildRustPackage {

    pname = "inori";
    version = "0-unstable-2025-04-28";

    src = fetchFromGitHub {
        owner = "MidAutumnMoon";
        repo = "InOri";
        rev = "0c167ab2dd08813d2ba83dfd057206c9225588ee";
        hash = "sha256-Lgqb8f7c1rmDEwL1rPwQxEm2Ubs63/bzAGzUPHOD3EE=";
    };

    cargoHash = "sha256-HrkXq7U0QagSS6CmYwwltklyZjb4g0swwT4r7C8oAoo=";
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

