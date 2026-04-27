# Not build from source because:
#
# 1) Upstream binary now (2025-04-21) are built with PGO
# 2) rust-analyzer took the longest time to build on CI
#   2.1) It would take twice the time if build from source with PGO

{
    lib,
    fetchurl,
    stdenv,
    autoPatchelfHook,

    makeBinaryWrapper,
    mimalloc,
}:

stdenv.mkDerivation rec {

    pname = "rust-analyzer";
    version = "2026-04-27";

    src = fetchurl rec {
        url = "${meta.homepage}/releases/download/${version}/${passthru.file}";
        hash = "sha256-ORAUf3kA8B5xnmGvDDDijPOIR+z+JBDyVm8YoAcQWSE=";
        passthru.file = "rust-analyzer-x86_64-unknown-linux-gnu.gz";
    };

    buildInputs = [
        stdenv.cc.cc.lib
    ];

    nativeBuildInputs = [
        autoPatchelfHook
        makeBinaryWrapper
    ];

    unpackPhase = ''
        gunzip -c "${src}" > "${pname}"
    '';

    installPhase = ''
        install -Dm755 "${pname}" "$out/bin/${pname}"
        wrapProgram "$out/bin/${pname}" \
            --inherit-argv0 \
            --set LD_PRELOAD "${mimalloc}/lib/libmimalloc.so"
    '';

    meta = with lib; {
        homepage = "https://github.com/rust-lang/rust-analyzer";
        license = with licenses; [ mit asl20 ];
        mainProgram = pname;
    };

}
