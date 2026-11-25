{
    lib,
    stdenvNoCC,
    fetchurl,
}:

stdenvNoCC.mkDerivation ( drvSelf: {

    pname = "metacubexd";
    version = "1.277.0";

    src = let
        repo = "https://github.com/MetaCubeX/metacubexd";
        dist = "compressed-dist.tgz";
    in fetchurl {
        url = "${repo}/releases/download/v${drvSelf.version}/${dist}";
        hash = "sha256-CRzYm6RuThIjomazbmJE0Rp+64R6eXgnndCT8luTO7I=";
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
