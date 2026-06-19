{
    lib,
    stdenvNoCC,
    fetchurl,
}:

stdenvNoCC.mkDerivation ( drvSelf: {

    pname = "metacubexd";
    version = "1.256.0";

    src = let
        repo = "https://github.com/MetaCubeX/metacubexd";
        dist = "compressed-dist.tgz";
    in fetchurl {
        url = "${repo}/releases/download/v${drvSelf.version}/${dist}";
        hash = "sha256-af2DC3CCsBMV73BAwn2zQzQ4OJZ+APS7VmFhu1/LAbo=";
    };

    sourceRoot = ".";

    installPhase = ''
        mkdir -pv "$out"
        cp -rv . "$out"
    '';

    postFixup = ''
        rm "$out/env-vars"
    '';

    meta = {
        license = lib.licenses.mit;
    };

} )
