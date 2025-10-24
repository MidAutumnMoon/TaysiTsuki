{
    lib,
    buildGoModule,
    fetchFromGitHub,
    installShellFiles,
}:

buildGoModule ( drvSelf: {

    pname = "sing-box";
    version = "1.13.0-alpha.26-unstable-2025-10-24";

    src = fetchFromGitHub {
        owner = "SagerNet";
        repo = "sing-box";
        rev = "c689437954453cf0a6997b05b40a4027407633f2";
        hash = "sha256-vE03cSs3IXrkb4kNKhwrZRfO0o3vB/I6oQCXTwMPFe4=";
    };

    vendorHash = "sha256-6Jvjk8VGwetbp9Ql0q7maYNKF+fXtejTxxdB/ARx7+k=";

    subPackages = [
        "cmd/sing-box"
    ];

    tags = [
        "with_quic"
        "with_clash_api"
        "with_utls"
        "badlinkname"
    ];

    ldflags = [
        "-s"
        "-X=github.com/sagernet/sing-box/constant.Version=${drvSelf.version}"
        "-checklinkname=0"
    ];

    env.GOAMD64 = "v3";
    env.CGO_ENABLED = 0;

    nativeBuildInputs = [ installShellFiles ];

    postInstall = ''
        installShellCompletion release/completions/sing-box.{bash,fish,zsh}
    '';

    meta = {
        homepage = "https://sing-box.sagernet.org";
        description = "Universal proxy platform";
        license = lib.licenses.gpl3Plus;
        mainProgram = "sing-box";
    };
} )
