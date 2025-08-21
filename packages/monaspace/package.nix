{
    lib,
    stdenvNoCC,
    tsuki,
    # 7z is faster than unzip
    _7zz,
}:

stdenvNoCC.mkDerivation (drvSelf: {
    pname = "monaspace";
    version = "1.300";

    src = tsuki.fetchGitHubRelease {
        owner = "githubnext";
        repo = "monaspace";
        tag = "v${drvSelf.version}";
        file = "monaspace-static-v${drvSelf.version}.zip";
        hash = "sha256-uFdgnJfc+MVeP8QIxr8+YrULUxItaxzGgTVU45y+vMw=";
    };
    
    dontUnpack = true;
    nativeBuildInputs = [ _7zz ];

    installPhase = ''
        declare -r dst="$out/share/fonts/opentype"
        mkdir -pv "$dst"
        7zz x "$src"
        
        # not interested in these fonts
        find -type d \
            \( -name "*Monaspace Krypton*" \
            -or -name "*Monaspace Radon*" \) \
            -exec rm -r "{}" +
            
        # remove the wide variations
        find -type f \
            \( -name "*-Wide*" -or -name "*-SemiWide*" \) \
            -exec rm "{}" +
        
        find -type f -name "*.otf" \
            -exec mv -t "$dst" "{}" +
    '';

    meta = {
        description = "Innovative superfamily of fonts for code";
        homepage = "https://monaspace.githubnext.com/";
        license = lib.licenses.ofl;
        platforms = lib.platforms.all;
    };
})
