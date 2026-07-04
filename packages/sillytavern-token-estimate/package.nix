{
    lib,
    stdenvNoCC,
    fetchFromGitHub,
}:

stdenvNoCC.mkDerivation {

    pname = "sillytavern-token-estimate";
    version = "0-unstable-2026-06-29";

    src = fetchFromGitHub {
        owner = "MidAutumnMoon";
        repo = "sillytavern-token-estimate";
        rev = "53cabbe00ade518aee9aa7e72c91158f139b24bb";
        hash = "sha256-2Spa6RRY6eDQnMSFgyHjppKs6sY2hIPmT7gIYvg5Ly4=";
    };

    installPhase = ''
        mkdir -p "$out"
        cp -r ./* "$out/"
    '';

    meta = {
        description = "Hijacks SillyTavern's token-count APIs and answers with a fast character-ratio estimate (~0.4 tok/char)";
        homepage = "https://github.com/MidAutumnMoon/sillytavern-token-estimate";
        license = lib.licenses.unfree;
        # No license file in the repo.
        maintainers = [ ];
        platforms = lib.platforms.all;
        # Pure JS data package — no nodejs runtime closure.
    };

}
