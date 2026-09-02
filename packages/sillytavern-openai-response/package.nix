{
    lib,
    stdenvNoCC,
    fetchFromGitHub,
}:

stdenvNoCC.mkDerivation {

    pname = "sillytavern-openai-response";
    version = "unstable";

    src = fetchFromGitHub {
        owner = "AES0529";
        repo = "SillyTavern-OpenAI-Responses";
        rev = "a18a009022bfc22c02ef38cdc264a3198906b542";
        hash = "sha256-7/oZFvMqK4+CFI1+v66Vue6bl1xynG1+cn/mJnIHi+I=";
    };

    installPhase = ''
        mkdir -p "$out"
        cp -r ./* "$out/"
    '';

    meta = {
        description = "OpenAI Responses API support for SillyTavern.";
        license = lib.licenses.agpl3;
        # No license file in the repo.
        maintainers = [ ];
        platforms = lib.platforms.all;
        # Pure JS data package — no nodejs runtime closure.
    };

}
