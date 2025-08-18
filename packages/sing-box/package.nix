{
    lib,
    buildGoLatestModule,
    fetchFromGitHub,
    installShellFiles,
}:

buildGoLatestModule ( drvSelf: {

    pname = "sing-box";
    version = "1.13.0-alpha.3-unstable-2025-08-18";

    src = fetchFromGitHub {
        owner = "SagerNet";
        repo = "sing-box";
        rev = "178d42636471a94e2e71f7ac3068cc5b909f0a10";
        hash = "sha256-kAfWXdD4ZNWvwgc/R5N/TbilhwoXaf8KcbYBTQZ4Qys=";
    };

    vendorHash = "sha256-kXyiZTLk18pdDGugc77wFBKQQJ4N92gUmIksovLxtFc=";

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
