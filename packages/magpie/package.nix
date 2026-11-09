{
    lib,
    buildGoModule,
    fetchFromGitHub,
}:

buildGoModule rec {

    pname = "magpie";
    version = "0.1.3421";

    src = fetchFromGitHub {
        owner = "yetone";
        repo = "magpie";
        tag = "v${version}";
        hash = "sha256-ekjCwmENjpO+HzvDcOwDFpHcJxbGnF3F0rlNbzosZCU=";
    };

    vendorHash = "sha256-7DZfVhaRhh5jmgoBH20eanUkkKovfTJ3552RQqvQMqg=";

    # Terminal-only build: no Wails, GTK 3 or WebKitGTK 4.1 — what
    # upstream's Dockerfile builds for `magpie serve`.
    tags = [ "nogui" ];
    subPackages = [ "." ];
    ldflags = [
        "-s"
        "-w"
        "-X main.version=${version}"
    ];

    doCheck = false;

    env.GOAMD64 = "v3";
    env.CGO_ENABLED = 0;

    meta = with lib; {
        description = "One local gateway for every agent's model";
        homepage = "https://usemagpie.ai";
        license = licenses.mit;
        mainProgram = "magpie";
        platforms = platforms.unix;
    };

}
