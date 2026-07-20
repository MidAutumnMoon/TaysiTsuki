{
    lib,
    fetchFromGitHub,
    buildGoModule,
}:

buildGoModule (drvSelf: {

    pname = "avahi2dns";
    version = "0.2.1";

    src = fetchFromGitHub {
        owner = "LouisBrunner";
        repo = "avahi2dns";
        tag = drvSelf.version;
        hash = "sha256-/FtgkDi7GRTQPBvtfT1CbTdrJ+VU2SRZbUILs/M5Dcw=";
    };

    vendorHash = "sha256-s+NuVtHmN963kNyaIsA5q9a+e1uDvQsH4qNDF63gk0Y=";

    env.CGO_ENABLED = 0;

    meta = with lib; {
        license = licenses.mit;
        platforms = platforms.linux;
        mainProgram = drvSelf.pname;
    };

})
