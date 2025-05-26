{
    lib,
    stdenvNoCC,
    fetchzip,

    rsync
}:

stdenvNoCC.mkDerivation rec {

    pname = "vuetorrent";
    version = "2.25.0";

    src = fetchzip rec {
        url = "${passthru.repo}/releases/download/v${version}/${pname}.zip";
        hash = "sha256-sOaQNw6AnpwNFEextgTnsjEOfpl3/lpoOZFgFOz7Bos=";
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
