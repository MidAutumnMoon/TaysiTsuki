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
    version = "0-unstable-2025-04-03";

    src = fetchFromGitHub {
        owner = "MidAutumnMoon";
        repo = "InOri";
        rev = "b97296e50bd15d48d32ce0e50c8a685b9a1f9bae";
        hash = "sha256-x9cAZJJuw4R51qdBnH0LI2odVd5zkhScI6kA/V9NFnE=";
    };

    cargoHash = "sha256-4vBhJBUoNK+JwECe6yoocuBQmA8ldTQYPU3yIBImMHo=";
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

