{
    lib,
    stdenv,
    tsuki,
    _7zz,
}:
stdenv.mkDerivation ( drvSelf: {

    pname = "peerbanhelper";
    version = "8.0.12";

    src = tsuki.fetchGitHubRelease {
        owner = "PBH-BTN";
        repo = "PeerBanHelper";
        tag = "v${drvSelf.version}";
        file = "PeerBanHelper_${drvSelf.version}.zip";
        hash = "sha256-V8K5ZBTl8pqAqYo3WA3jIwYpFKqIIyYIxux0JxDXBXo=";
    };

    dontUnpack = true;
    nativeBuildInputs = [ _7zz ];

    installPhase = ''
        declare -r dst="$out${drvSelf.passthru.libPath}"
        mkdir -pv "$dst"
        7zz x "$src"
        
        find -type d -name "libraries" -exec cp -r -t "$dst" {} +
        find -type f -name "PeerBanHelper.jar" -exec cp -t "$dst" {} +
    '';
    
    passthru = rec {
        libPath = "/libexec/peerbanhelper";
        jarPath = "${tsuki.peerbanhelper}${libPath}/PeerBanHelper.jar";
    };

    meta = {
        license = lib.licenses.gpl3Plus;
        homepage = "https://github.com/PBH-BTN/PeerBanHelper";
    };

} )
