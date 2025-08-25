{
    lib,
    buildGoLatestModule,
    fetchFromGitHub,
    installShellFiles,
}:

buildGoLatestModule ( drvSelf: {

    pname = "sing-box";
    version = "1.13.0-alpha.5-unstable-2025-08-24";

    src = fetchFromGitHub {
        owner = "SagerNet";
        repo = "sing-box";
        rev = "3145f8c54cc0c5ea6a20069fc90b88e7ae13057c";
        hash = "sha256-ir4Md/NpZGYTuKaiKUVutEihczfIWN8Tlzh9Pdr21Zw=";
    };

    vendorHash = "sha256-bfGCXnzVgpzVjmQaOzvbx/VUbY1jRKvwIisX+1pU6vA=";

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
