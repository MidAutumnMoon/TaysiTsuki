{
    stdenvNoCC,
    zstd,
    tsuki,
}:

stdenvNoCC.mkDerivation rec {

    pname = "adblocklist";
    version = "2026-02-16.034258";

    src = tsuki.fetchGitHubRelease {
        owner = "MidAutumnMoon";
        repo = "combined-anti-ad-dns-blocklist";
        tag = version;
        file = "assets.tar.zst";
        hash = "sha256-mFxZM+kgJS16/PCQtth1Q3L//hu/+KmUyFS4EaP1clA=";
    };

    nativeBuildInputs = [ zstd ];

    unpackPhase = ''
        mkdir -p "$out"
        tar xaf "$src" -C "$out"
    '';

}
