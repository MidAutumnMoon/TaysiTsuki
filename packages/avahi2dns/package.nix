{
    lib,
    fetchFromGitHub,
    buildGoModule,
}:

buildGoModule (drvSelf: {

    pname = "avahi2dns";
    version = "0.1.0";

    src = fetchFromGitHub {
        owner = "LouisBrunner";
        repo = "avahi2dns";
        tag = drvSelf.version;
        hash = "sha256-/ugdPLhWa76/rtFRWr4pHhmuvYxIB0sbNnw4m6vnNSg=";
    };

    vendorHash = "sha256-rROxPRFsQC852leigEqfhyoL+e2metSmLNR98WJBEfw=";

    env.CGO_ENABLED = 0;

    meta = with lib; {
        license = licenses.mit;
        platforms = platforms.linux;
        mainProgram = drvSelf.pname;
    };

})
