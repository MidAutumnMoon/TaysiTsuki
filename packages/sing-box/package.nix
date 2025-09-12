{
    lib,
    buildGoLatestModule,
    fetchFromGitHub,
    installShellFiles,
}:

buildGoLatestModule ( drvSelf: {

    pname = "sing-box";
    version = "1.13.0-alpha.11-unstable-2025-09-12";

    src = fetchFromGitHub {
        owner = "SagerNet";
        repo = "sing-box";
        rev = "764c2ca8e238b8334d2ddd99e52fe648b46e2d9d";
        hash = "sha256-WU4qFLvtcStXtwv8ygy+9T4Ymh+Jh4lOWVUPC6hwFd0=";
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
