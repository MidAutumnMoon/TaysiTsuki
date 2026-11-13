{
    lib,
    buildGoModule,
    fetchFromGitHub,
}:

buildGoModule rec {

    pname = "magpie";
    version = "0.1.4087";

    src = fetchFromGitHub {
        owner = "yetone";
        repo = "magpie";
        tag = "v${version}";
        hash = "sha256-hnqkOq7rCJIFZuZ+Z8/M63/PMl5TDum1GIc2XdiNkpc=";
    };

    vendorHash = "sha256-nxO7lvPHI5L8iHuVfjPBjSUOui/OdlQ/9uGW/7GpmtE=";

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
