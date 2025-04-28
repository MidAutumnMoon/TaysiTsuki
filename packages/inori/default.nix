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
        rev = "1684de1f2a5b07d8ee59e56bed065b2687ba9d60";
        hash = "sha256-XA29WvpGRryJB2svhR6YgYGA8QVgd2pjD1Oz5RyiKqY=";
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

