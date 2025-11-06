{
    stdenvNoCC,
    fetchurl,
    zstd,
    tsuki,
}:

stdenvNoCC.mkDerivation rec {

    pname = "adblocklist";
    version = "2025-11-06.090923";

    src = tsuki.fetchGitHubRelease {
        owner = "MidAutumnMoon";
        repo = "combined-anti-ad-dns-blocklist";
        tag = version;
        file = "assets.tar.zst";
        hash = "sha256-b4cvWbIV3Gu1YSQavoP8VsakCDafaSC1QDw6azz46tU=";
    };

    nativeBuildInputs = [ zstd ];

    unpackPhase = ''
        mkdir -p "$out"
        tar xaf "$src" -C "$out"
    '';

}
