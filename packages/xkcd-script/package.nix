{
    lib,
    stdenvNoCC,
    tsuki,
}:

stdenvNoCC.mkDerivation (drvSelf: {
    pname = "xkcd-script";
    version = "2026.2";

    src = tsuki.fetchGitHubRelease {
        owner = "ipython";
        repo = "xkcd-font";
        tag = "v${drvSelf.version}";
        file = "xkcd-script-${drvSelf.version}.otf";
        hash = "sha256-aWyzoHgVSCGcdcV/eoFBkVEsEVeXrTjHtnsu64Vxo50=";
    };

    dontUnpack = true;

    installPhase = ''
        declare -r dst="$out/share/fonts/opentype"
        mkdir -pv "$dst"
        install -m644 "$src" "$dst/xkcd-script.otf"
    '';

    meta = {
        description = "Handwritten-style font derived from Randall Munroe's handwriting";
        homepage = "https://github.com/ipython/xkcd-font";
        license = lib.licenses.cc-by-nc-30;
        platforms = lib.platforms.all;
    };
})
