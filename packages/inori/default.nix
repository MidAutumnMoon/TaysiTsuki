{
    lib,
    stdenv,
    fetchFromGitHub,

    rustTeapot,

    libavif,
    libjxl,
    imagemagick,
}:

let

    cjxl = lib.getExe' libjxl "cjxl";
    avifenc = lib.getExe' libavif "avifenc";
    magick = lib.getExe' imagemagick "magick";

in

rustTeapot.buildRustPackage {

    pname = "inori";
    version = "0-unstable-2025-04-21";

    src = fetchFromGitHub {
        owner = "MidAutumnMoon";
        repo = "InOri";
        rev = "3012f688efbb1d7866c136262aedd085645eb245";
        hash = "sha256-aF6uO+3TIAXHlI51ykOZDdNP9oBWW1D860R/n5VorEc=";
    };

    cargoHash = "sha256-/lzEc9rkD6BozFWLtBnq3knYNKUavhlL/qeJUdv5m1k=";
    useFetchCargoVendor = true;

    env.CFG_CJXL_PATH = cjxl;
    env.CFG_AVIFENC_PATH = avifenc;
    env.CFG_MAGICK_PATH = magick;

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

