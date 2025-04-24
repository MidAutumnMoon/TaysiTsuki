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
    version = "0-unstable-2025-04-21";

    src = fetchFromGitHub {
        owner = "MidAutumnMoon";
        repo = "InOri";
        rev = "c5d5b7309f19b5c37492b82f1247765c224c4c5c";
        hash = "sha256-VM6GKLMgw+ORTeRoRt6BGY4DkVQMdaUtZBOmGTvd830=";
    };

    cargoHash = "sha256-/lzEc9rkD6BozFWLtBnq3knYNKUavhlL/qeJUdv5m1k=";
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

