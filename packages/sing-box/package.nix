{
    lib,
    buildGoLatestModule,
    fetchFromGitHub,
    installShellFiles,
}:

buildGoLatestModule ( drvSelf: {

    pname = "sing-box";
    version = "1.13.0-alpha.8-unstable-2025-09-08";

    src = fetchFromGitHub {
        owner = "SagerNet";
        repo = "sing-box";
        rev = "4b4c1ab2c7749d6dd53d1021eec4376847d46f4f";
        hash = "sha256-L6KYZfo0AKolL7C+CdX/MN6QEuDbg39l2Pklxg41GRg=";
    };

    vendorHash = "sha256-+Tyn0morVBemDEXCbnPFZesCOE9cbfTy7GRp073SXTM=";

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
