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
    version = "0-unstable-2025-04-15";

    src = fetchFromGitHub {
        owner = "MidAutumnMoon";
        repo = "InOri";
        rev = "b485450e5ba58b258235e45ed46a5cc51366eadd";
        hash = "sha256-v6vBGpRVKh2X1UQAQJr9WU5xggFP3lE1x7BF28XWEa4=";
    };

    cargoHash = "sha256-KrW+a0nrnakQeWNyoeqHffUw1qM/u7CnAj9hkcl1U+c=";
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

