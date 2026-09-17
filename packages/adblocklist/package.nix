{
    stdenvNoCC,
    zstd,
    tsuki,
}:

stdenvNoCC.mkDerivation rec {

    pname = "adblocklist";
    version = "2026-09-16.054722";

    src = tsuki.fetchGitHubRelease {
        owner = "MidAutumnMoon";
        repo = "combined-anti-ad-dns-blocklist";
        tag = version;
        file = "assets.tar.zst";
        hash = "sha256-gyde7XUk28ChprKmKMzO3pOeg00icRSa3yHVCW/BVn8=";
    };

    nativeBuildInputs = [ zstd ];

    unpackPhase = ''
        mkdir -p "$out"
        tar xaf "$src" -C "$out"
    '';

}
