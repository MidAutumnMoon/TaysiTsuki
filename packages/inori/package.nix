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
    version = "0-unstable-2025-06-02";

    src = fetchFromGitHub {
        owner = "MidAutumnMoon";
        repo = "InOri";
        rev = "601ec11f3a77bafd9c3d9f2c21f65828c42b89e9";
        hash = "sha256-z272SQc/YKnJ9E6KZ3sSwFlixUUFHNds218OiV7yS/M=";
    };

    cargoHash = "sha256-9/6lIy5ohGFZQwiAgkFj79D/dUuMGA+//VlKG40cIek=";
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

