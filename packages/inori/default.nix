{
    lib,
    stdenv,
    fetchFromGitHub,

    rustTeapot,

    libavif,
    libyuv_teapot,
    libjxl,
}:

let

    cjxl = "${lib.getBin libjxl}/bin/cjxl";

    avifenc =
        libavif.override { libyuv = libyuv_teapot; }
        |> ( p: "${lib.getBin p}/bin/avifenc" )
    ;

in

rustTeapot.buildRustPackage {

    pname = "inori";
    version = "0-unstable-2025-04-01";

    src = fetchFromGitHub {
        owner = "MidAutumnMoon";
        repo = "InOri";
        rev = "6c13945a78de235d594f3c0264ac347ba3824a7d";
        hash = "sha256-fudZafil6Vkok7X23ncKMZ6NNtyMVp5QX8IgnzMh74Q=";
    };

    cargoHash = "sha256-oYtf1ln1f7tpqcE+6lV5jsvTmZ9zAkyi3JlLUM69sbo=";
    useFetchCargoVendor = true;

    env.CFG_CJXL_PATH = cjxl;
    env.CFG_AVIFENC_PATH = avifenc;

    RUSTFLAGS = with stdenv;
        lib.optional hostPlatform.isx86_64 "-Ctarget-cpu=x86-64-v3"
    ;

    postInstall = /* bash */ ''
        # Remove benchmarking binaries
        find "$out" \
            -type f -iname "*_bench" \
            -exec rm -v "{}" +
        ln -sv "$out/bin/coruma-reverse" "$out/bin/,?"
    '';

    meta = {
        homepage = "https://github.com/MidAutumnMoon/InOri";
        license = lib.licenses.gpl3Plus;
    };

}

