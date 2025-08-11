{
    lib,
    stdenvNoCC,
    fetchurl,
}:

stdenvNoCC.mkDerivation ( drvSelf: {

    pname = "metacubexd";
    version = "1.189.1";

    src = let
        repo = "https://github.com/MetaCubeX/metacubexd";
        dist = "compressed-dist.tgz";
    in fetchurl {
        url = "${repo}/releases/download/v${drvSelf.version}/${dist}";
        hash = "sha256-yWO7fHihQP2RG3TLMrVj/l5nAXdEauxtg4BxLBG9Zeg=";
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
