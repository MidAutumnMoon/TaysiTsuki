{
    stdenvNoCC,
    zstd,
    tsuki,
}:

stdenvNoCC.mkDerivation rec {

    pname = "adblocklist";
    version = "2026-02-01.034930";

    src = tsuki.fetchGitHubRelease {
        owner = "MidAutumnMoon";
        repo = "combined-anti-ad-dns-blocklist";
        tag = version;
        file = "assets.tar.zst";
        hash = "sha256-sgWZFM46HgrSkNOdV0tjvSTLFDIvr6/1VoVew7mdBqA=";
    };

    nativeBuildInputs = [ zstd ];

    unpackPhase = ''
        mkdir -p "$out"
        tar xaf "$src" -C "$out"
    '';

}
