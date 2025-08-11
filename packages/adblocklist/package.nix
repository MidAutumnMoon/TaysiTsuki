{
    stdenvNoCC,
    fetchurl,
    zstd,
}:

stdenvNoCC.mkDerivation rec {

    pname = "adblocklist";
    version = "2025-08-08.025808";

    src = fetchurl {
        url = "${meta.homepage}/releases/download/${version}/dnscrypt-blocklist.txt.zstd";
        hash = "sha256-sXWiz93nAvR1X7oODQHeJjXf7o5xiqGc59k4WlhCzRQ=";
    };

    dontUnpack = true;

    nativeBuildInputs = [ zstd ];

    installPhase = ''
        unzstd "$src" -o "$out"
    '';

    meta = {
        homepage = "https://github.com/MidAutumnMoon/combined-anti-ad-dns-blocklist";
    };

}

# vim: nowrap:
