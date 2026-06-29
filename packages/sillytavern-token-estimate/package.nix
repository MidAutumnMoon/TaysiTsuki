{
    lib,
    stdenvNoCC,
    fetchFromGitHub,
}:

stdenvNoCC.mkDerivation {

    pname = "sillytavern-token-estimate";
    version = "unstable-2026-06-29";

    src = fetchFromGitHub {
        owner = "MidAutumnMoon";
        repo = "sillytavern-token-estimate";
        rev = "41f66c1268867120097363f7bd9b8713c9112d48";
        hash = "sha256-QvE0p0D79/BZJruA4fkeCIcT+MUeFYPh6S7awwso1A0=";
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
