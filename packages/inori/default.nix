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
    version = "0-unstable-2025-04-14";

    src = fetchFromGitHub {
        owner = "MidAutumnMoon";
        repo = "InOri";
        rev = "f6fec47443b5711962cce25db86db6bcf308fe5b";
        hash = "sha256-xRC9qpfBDGfvo+GMkCxCl+vlDle9X9JTgZwuFL5Cwag=";
    };

    cargoHash = "sha256-2j1rz3qv8OjqXRoHDM3OG3I5H5xEQzknQh+coUhIYnI=";
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

