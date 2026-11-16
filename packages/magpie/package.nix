{
    lib,
    buildGoModule,
    fetchFromGitHub,
}:

buildGoModule rec {

    pname = "magpie";
    version = "0.1.4341";

    src = fetchFromGitHub {
        owner = "yetone";
        repo = "magpie";
        tag = "v${version}";
        hash = "sha256-4n6IN5I3ZORXQa068S5X72745NI8R9MfGuomuDE6CKY=";
    };

    vendorHash = "sha256-TgMwl324YTy8l9zlkjK/aAqJafP/m3ZbiLLDl1OrffY=";

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
