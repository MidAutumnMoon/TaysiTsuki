{
    lib,
    buildGoLatestModule,
    fetchFromGitHub,
    installShellFiles,
}:

buildGoLatestModule ( drvSelf: {

    pname = "sing-box";
    version = "1.13.0-alpha.17-unstable-2025-09-19";

    src = fetchFromGitHub {
        owner = "SagerNet";
        repo = "sing-box";
        rev = "2c2d261543b774c4171155f8cf034fa0da3ccb11";
        hash = "sha256-LEpwhmVhNeDv/KtElthQdmMzb4ABmubEKDEia+Tx81s=";
    };

    vendorHash = "sha256-rHseMBgehzjREJqeEpj4mVMTp8buW8NwVdHru5B9Q/E=";

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
    env.GOEXPERIMENT = "greenteagc";

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
