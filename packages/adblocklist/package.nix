{
    stdenvNoCC,
    zstd,
    tsuki,
}:

stdenvNoCC.mkDerivation rec {

    pname = "adblocklist";
    version = "2026-03-01.034225";

    src = tsuki.fetchGitHubRelease {
        owner = "MidAutumnMoon";
        repo = "combined-anti-ad-dns-blocklist";
        tag = version;
        file = "assets.tar.zst";
        hash = "sha256-k75lIdAXb0nLsxA9MkzVKpmWITft9UjuepqHZLEUU40=";
    };

    nativeBuildInputs = [ zstd ];

    unpackPhase = ''
        mkdir -p "$out"
        tar xaf "$src" -C "$out"
    '';

}
