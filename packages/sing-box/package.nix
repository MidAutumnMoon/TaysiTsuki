{
    lib,
    buildGoLatestModule,
    fetchFromGitHub,
    installShellFiles,
}:

buildGoLatestModule ( drvSelf: {

    pname = "sing-box";
    version = "1.13.0-alpha.5-unstable-2025-08-22";

    src = fetchFromGitHub {
        owner = "SagerNet";
        repo = "sing-box";
        rev = "c002b8321e86cdfd0a8cf9b4b5f2615b80a1dfd4";
        hash = "sha256-MJcJ3jSuTejVtIM1HWZGnKI+jou7/g2EcP9A3uPYd60=";
    };

    vendorHash = "sha256-JnMkgxbVJnlFrn3bxwsbLatlqd70tTH5OlO6Q9JKI7M=";

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
