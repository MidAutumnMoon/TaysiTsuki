{
    lib,
    fetchFromGitHub,

    go,
    buildGoLatestModule,
}:

buildGoLatestModule rec {

    pname = "hysteria";
    version = "2.6.3";

    src = fetchFromGitHub {
        owner = "apernet";
        repo = "hysteria";
        tag = "app/v${version}";
        hash = "sha256-0gXvox+/HPeyLbpyVGgP+40bsAgZZWs7MrLkdMFcqX8=";
    };

    vendorHash = "sha256-mlRYtndWPG0nUXdmBRvNRs9yUfA2KdFKhpFBP+2O8Io=";

    sourceRoot = "${src.name}/app";
    # sourceRoot is alreay at "app"
    subPackages = [ "." ];

    env.GOWORK = "off";
    env.GOAMD64 = "v3";
    env.CGO_ENABLED = 0;
    env.GOEXPERIMENT = "greenteagc";

    doCheck = false;

    ldflags = let
        # see "hyperbole.py"
        cmd = "github.com/apernet/hysteria/app/v2/cmd";
    in [
        "-s" "-w"
        "-X ${cmd}.appVersion=${version}"
        "-X ${cmd}.appType=release"
        "-X ${cmd}.appToolchain=${go.version}"
    ];

    postInstall = ''
        mv $out/bin/{"app",${pname}}
    '';

    meta = with lib; {
        homepage = "https://github.com/apernet/hysteria";
        license = licenses.mit;
        platforms = platforms.unix;
        mainProgram = pname;
    };

}
