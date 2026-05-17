{
    lib,
    fetchFromGitHub,
    buildGoModule,
}:

buildGoModule (drvSelf: {

    pname = "avahi2dns";
    version = "0.2.0";

    src = fetchFromGitHub {
        owner = "LouisBrunner";
        repo = "avahi2dns";
        tag = drvSelf.version;
        hash = "sha256-F4P/g/x+gK1+84ubXK52xhvAfVddhdbrrEo9A0sdjC4=";
    };

    vendorHash = "sha256-BSepcq0LKwEtetYhs/dQ2y5EkCAbkSlpRlWHrhlfqmc=";

    env.CGO_ENABLED = 0;

    meta = with lib; {
        license = licenses.mit;
        platforms = platforms.linux;
        mainProgram = drvSelf.pname;
    };

})
