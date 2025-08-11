{
    lib,
    buildGoModule,
    fetchFromGitHub,
    installShellFiles,
}:

buildGoModule ( drvSelf: {

    pname = "sing-box";
    version = "1.12.1";

    src = fetchFromGitHub {
        owner = "SagerNet";
        repo = "sing-box";
        tag = "v${drvSelf.version}";
        hash = "sha256-fo5xO081IX+rPA5yZ0P2dxSZsVHsBTJeCJmI0dSgGyE=";
    };

    vendorHash = "sha256-sWWiPDUEc+EBzLmd+QYYVdecqhKBeKkPABEp6jFqraw=";

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
