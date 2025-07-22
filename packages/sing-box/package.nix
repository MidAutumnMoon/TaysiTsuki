{
    lib,
    buildGoModule,
    fetchFromGitHub,
    installShellFiles,
}:

buildGoModule ( drvSelf: {

    pname = "sing-box";
    version = "1.12.0-rc.1";

    src = fetchFromGitHub {
        owner = "SagerNet";
        repo = "sing-box";
        rev = "1e068c78e67ed05796d410e4c18ef01d4576d012";
        hash = "sha256-eh717ZeGACOHPl41c8c2ko5NVAZxK++BG/luB0DRugk=";
    };

    vendorHash = "sha256-PXCLsuasZNROI04wLe69PC1XclazoWUJBjTQoRzWn8Q=";

    subPackages = [
        "cmd/sing-box"
    ];

    tags = [
        "with_quic"
        "with_clash_api"
    ];

    ldflags = [
        "-s"
        "-X=github.com/sagernet/sing-box/constant.Version=${drvSelf.version}"
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
