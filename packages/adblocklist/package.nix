{
    stdenvNoCC,
    fetchurl,
    zstd,
}:

stdenvNoCC.mkDerivation rec {

    pname = "adblocklist";
    version = "2025-06-17.024558";

    src = fetchurl {
        url = "${meta.homepage}/releases/download/${version}/dnscrypt-blocklist.txt.zstd";
        hash = "sha256-A/MIaYG+vrVC4JfA0ZX6Smu2ifPcQ/z4qu7srDGYK8o=";
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
