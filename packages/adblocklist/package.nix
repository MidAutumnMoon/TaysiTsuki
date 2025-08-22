{
    stdenvNoCC,
    fetchurl,
    zstd,
}:

stdenvNoCC.mkDerivation rec {

    pname = "adblocklist";
    version = "2025-08-22.022642";

    src = fetchurl {
        url = "${meta.homepage}/releases/download/${version}/dnscrypt-blocklist.txt.zstd";
        hash = "sha256-KPlzG+LHzbaTz5zBvwtDW6/Yozbci2jZ+VqZdgxY9UY=";
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
