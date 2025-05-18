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
    version = "0-unstable-2025-05-17";

    src = fetchFromGitHub {
        owner = "MidAutumnMoon";
        repo = "InOri";
        rev = "6cfe8a6ff3b899c9f5aae18d87595f70cd029509";
        hash = "sha256-3NFR+FQqb4vmHYyr+24UepKFeVLU64PQc5vGOGshGrU=";
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

