{
    lib,
    buildGoModule,
    fetchFromGitHub,
    installShellFiles,
}:

buildGoModule ( drvSelf: {

    pname = "sing-box";
    version = "1.13.0-alpha.1-unstable-2025-08-15";

    src = fetchFromGitHub {
        owner = "SagerNet";
        repo = "sing-box";
        rev = "e9d9c7ae87372b98770b34d465c26a1d6301f0f4";
        hash = "sha256-L/fykhdxVv6v5lPhERJVjcq0TZI+0LDPhdIvMUFJANI=";
    };

    vendorHash = "sha256-NLIf/1qDC2Na7pOcm/c+g2B6IZD4VS9Kh9e9jCCDG/Y=";

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
