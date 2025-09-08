{
    lib,
    buildGoLatestModule,
    fetchFromGitHub,
    installShellFiles,
}:

buildGoLatestModule ( drvSelf: {

    pname = "sing-box";
    version = "1.13.0-alpha.9-unstable-2025-09-08";

    src = fetchFromGitHub {
        owner = "SagerNet";
        repo = "sing-box";
        rev = "64384c75fae7a3f726ac0ada8fcb372a86276173";
        hash = "sha256-YqKuEGTBV70+c3zGIXhWlKIgpaxcsZjuVOs+ymfmodo=";
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
