{
    stdenvNoCC,
    fetchurl,
    zstd,
}:

stdenvNoCC.mkDerivation rec {

    pname = "adblocklist";
    version = "2025-07-29.030502";

    src = fetchurl {
        url = "${meta.homepage}/releases/download/${version}/dnscrypt-blocklist.txt.zstd";
        hash = "sha256-7KE906eWaVikhRVBY8C4DUOd47r3GTEzdVm5QfPtqwk=";
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
