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
}:

stdenv.mkDerivation rec {

    pname = "rust-analyzer";
    version = "2025-05-05";

    src = fetchurl rec {
        url = "${meta.homepage}/releases/download/${version}/${passthru.file}";
        hash = "sha256-SeM7i41ScPeDfz1Knw5DW/jT+i1z3kxNaHkgUD/TB0I=";
        passthru.file = "rust-analyzer-x86_64-unknown-linux-gnu.gz";
    };

    buildInputs = [
        stdenv.cc.cc.lib
    ];

    nativeBuildInputs = [
        autoPatchelfHook
    ];

    dontUnpack = true;

    installPhase = ''
        gunzip -c "${src}" > "${pname}"
        install -Dm755 "${pname}" "$out/bin/${pname}"
    '';

    meta = with lib; {
        homepage = "https://github.com/rust-lang/rust-analyzer";
        license = with licenses; [ mit asl20 ];
        mainProgram = pname;
    };

}
