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
    version = "0-unstable-2025-04-08";

    src = fetchFromGitHub {
        owner = "MidAutumnMoon";
        repo = "InOri";
        rev = "805d3173b9644b3d192b8a85c54caa51704cab50";
        hash = "sha256-zn0Z4y2QPVoMRvESx1r+aYGitKjZ+U6ZHtf4gPQ0ZgE=";
    };

    cargoHash = "sha256-4vBhJBUoNK+JwECe6yoocuBQmA8ldTQYPU3yIBImMHo=";
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

