{
    lib,
    buildGoLatestModule,
    fetchFromGitHub,
    installShellFiles,
}:

buildGoLatestModule ( drvSelf: {

    pname = "sing-box";
    version = "1.13.0-alpha.8-unstable-2025-09-07";

    src = fetchFromGitHub {
        owner = "SagerNet";
        repo = "sing-box";
        rev = "6e6ab676019d007ef7f972a36960fe60e680f043";
        hash = "sha256-zZVMdkg4vG+wFYct2lj15fxvQPRYq8IqkDVStQWqjCo=";
    };

    vendorHash = "sha256-nqWZ2F9FmoIQpkJRf6s82aQNMPjb02r3qrj2LCr5dTA=";

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
