{
    lib,
    fetchFromGitHub,

    go,
    buildGoLatestModule,
}:

buildGoLatestModule rec {

    pname = "hysteria";
    version = "2.6.4";

    src = fetchFromGitHub {
        owner = "apernet";
        repo = "hysteria";
        tag = "app/v${version}";
        hash = "sha256-j6MvVq/+buv/Md/84xUFyRh2zp8qms/1IdEREZ5trXM=";
    };

    vendorHash = "sha256-IKcgMrTPRwQRm2cEvp3KgREpxH8nY9lZmGlu3xySSw4=";

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
