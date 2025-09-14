{
    lib,
    buildGoLatestModule,
    fetchFromGitHub,
    installShellFiles,
}:

buildGoLatestModule ( drvSelf: {

    pname = "sing-box";
    version = "1.13.0-alpha.14-unstable-2025-09-13";

    src = fetchFromGitHub {
        owner = "SagerNet";
        repo = "sing-box";
        rev = "e18c729cc08ac7dc9e3e98d6051dd6bc7fea8f76";
        hash = "sha256-Pd6NK5c4Tq/48j4n9MeaQjSIG0ZizrjEOaDiU9Z9nNU=";
    };

    vendorHash = "sha256-yWPdJikASamoKQr6keu6dFc+75xFG62JOXZBtPzEUI0=";

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
