{
    lib,
    stdenvNoCC,
    fetchzip,

    rsync
}:

stdenvNoCC.mkDerivation rec {

    pname = "vuetorrent";
    version = "2.27.0";

    src = fetchzip rec {
        url = "${passthru.repo}/releases/download/v${version}/${pname}.zip";
        hash = "sha256-HGvYQlLzME3V8LbGAuTmeWvc/xjjiSaAeki+kxfiA7M=";
        passthru.repo = "https://github.com/VueTorrent/VueTorrent";
    };

    nativeBuildInputs = [ rsync ];

    installPhase = ''
        mkdir -p "$out"
        # N.B. both paths end with "/"
        rsync -avP "$src/public/" "$out/"
    '';

    meta = {
        license = lib.licenses.gpl3Only;
        homepage = src.passthru.repo;
    };

}
