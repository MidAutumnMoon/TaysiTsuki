{
    stdenvNoCC,
    fetchurl,
    zstd,
}:

stdenvNoCC.mkDerivation rec {

    pname = "adblocklist";
    version = "2025-06-19.024531";

    src = fetchurl {
        url = "${meta.homepage}/releases/download/${version}/dnscrypt-blocklist.txt.zstd";
        hash = "sha256-jXGJTx3G7ZtfQAlF1QRjqmLSd6yc9s6+jZm9E0KAnoQ=";
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
