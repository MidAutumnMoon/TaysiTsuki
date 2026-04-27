{
    lib,
    fetchFromGitHub,

    go,
    buildGoModule,
}:

buildGoModule rec {

    pname = "hysteria";
    version = "2.8.2";

    src = fetchFromGitHub {
        owner = "apernet";
        repo = "hysteria";
        tag = "app/v${version}";
        hash = "sha256-HgZVwaHL5q8aOxHhVt6RaHaBxoj83ujHaqLemQkLRUM=";
    };

    vendorHash = "sha256-6kZ8Eq/OowGG6KbKXtGo480KjXG1l30JnCLRXAS7bXw=";

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
