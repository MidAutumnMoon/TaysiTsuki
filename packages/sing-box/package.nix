{
    lib,
    buildGoLatestModule,
    fetchFromGitHub,
    installShellFiles,
}:

buildGoLatestModule ( drvSelf: {

    pname = "sing-box";
    version = "1.13.0-alpha.6-unstable-2025-08-26";

    src = fetchFromGitHub {
        owner = "SagerNet";
        repo = "sing-box";
        rev = "abf69fefbacf6b1234350cd2662d10c7c1af5415";
        hash = "sha256-nBf3cWiKdcZBy/Za1pXN6swgGZkYUbsqLSlhrFFhwL8=";
    };

    vendorHash = "sha256-rq1TjPCXdWyw6xYAqxRveA1RIfjjFplLdS71ylVuhbs=";

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
