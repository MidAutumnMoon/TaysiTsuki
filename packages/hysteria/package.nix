{
    lib,
    fetchFromGitHub,

    go,
    buildGoModule,
}:

buildGoModule rec {

    pname = "hysteria";
    version = "2.9.2";

    src = fetchFromGitHub {
        owner = "apernet";
        repo = "hysteria";
        tag = "app/v${version}";
        hash = "sha256-42tXqHMHh8QMRcKl92e6UlSeGLgo28x3J8YW8t3F6dY=";
    };

    vendorHash = "sha256-kAPijL+wblFvzF1efKUUSDMDJqYtDt5B44aXhImOd78=";

    sourceRoot = "${src.name}/app";
    # sourceRoot is alreay at "app"
    subPackages = [ "." ];

    env.GOWORK = "off";
    env.GOAMD64 = "v3";
    env.CGO_ENABLED = 0;

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
