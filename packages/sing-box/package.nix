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
        rev = "12e8d43925369298d60643cffcef0ab3da703b13";
        hash = "sha256-vkAAzAne2tU56u7mI9LvKv7M1nnrYFS9Rz/bqC+uEe4=";
    };

    vendorHash = "sha256-fN1uyhnl0ECF8c6vX8/ZAZKPZhlwYcUBy5Xi+5pbuQM=";

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
