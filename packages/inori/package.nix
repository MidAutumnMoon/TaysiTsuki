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
        rev = "669f9a584c06046e2bfa1b57abfeb2a2e45704b5";
        hash = "sha256-UMjqf2YVuJ1KSn4Jk8fpl+7GSF9lEhFNzQTYRrPu0WA=";
    };

    cargoHash = "sha256-oiJ+Ck17c9aUCtS3SVr1cjQ6JTTE8vNT11FLFLzun6k=";
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

