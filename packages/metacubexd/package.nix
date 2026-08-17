{
    lib,
    stdenvNoCC,
    fetchurl,
}:

stdenvNoCC.mkDerivation ( drvSelf: {

    pname = "metacubexd";
    version = "1.273.0";

    src = let
        repo = "https://github.com/MetaCubeX/metacubexd";
        dist = "compressed-dist.tgz";
    in fetchurl {
        url = "${repo}/releases/download/v${drvSelf.version}/${dist}";
        hash = "sha256-B24F0uPcZkGg7CgapLl6GBk/vMN50Tl2LDLZCtsieTw=";
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
