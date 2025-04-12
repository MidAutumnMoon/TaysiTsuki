{
    lib,
    stdenv,
    fetchFromGitHub,

    rustTeapot,

    libavif,
    libjxl,
}:

let

    cjxl = lib.getExe' libjxl "cjxl";
    avifenc = lib.getExe' libavif "avifenc";

in

rustTeapot.buildRustPackage {

    pname = "inori";
    version = "0-unstable-2025-04-11";

    src = fetchFromGitHub {
        owner = "MidAutumnMoon";
        repo = "InOri";
        rev = "a620908e2d4e73fe5af08eb73f735c44f4cdfe05";
        hash = "sha256-Y2L01uC89p+hChARP3teFJocADVxEke6o0c4zNYthxU=";
    };

    cargoHash = "sha256-tpC7dInOA7qX2JoUrVknSd8JAyJyR4lKsC0me5FeBqs=";
    useFetchCargoVendor = true;

    env.CFG_CJXL_PATH = cjxl;
    env.CFG_AVIFENC_PATH = avifenc;

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

