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
    version = "0-unstable-2025-04-20";

    src = fetchFromGitHub {
        owner = "MidAutumnMoon";
        repo = "InOri";
        rev = "20c5b04e43b9d941703c08c8ead75b167ed7a2bf";
        hash = "sha256-FPbyDkJRx9Kpmqs1LBFDd40uuOsXWp7+0GLr0yVx4nY=";
    };

    cargoHash = "sha256-OGNGcGAjwsI85NWVIzWp+cIzJ8iZOyoDC27oMuYsnJg=";
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

