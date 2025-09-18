{
    lib,
    buildGoLatestModule,
    fetchFromGitHub,
    installShellFiles,
}:

buildGoLatestModule ( drvSelf: {

    pname = "sing-box";
    version = "1.13.0-alpha.16-unstable-2025-09-18";

    src = fetchFromGitHub {
        owner = "SagerNet";
        repo = "sing-box";
        rev = "b5c1b07c3d29b78cd770349147bc18fd6f8283f0";
        hash = "sha256-Vl9Mm3bjnhfsdSDxEaesnLRiUIpucTrwBLV0Utkw4JY=";
    };

    vendorHash = "sha256-rHseMBgehzjREJqeEpj4mVMTp8buW8NwVdHru5B9Q/E=";

    subPackages = [
        "cmd/sing-box"
    ];

    tags = [
        "with_quic"
        "with_clash_api"
        "with_utls"
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
