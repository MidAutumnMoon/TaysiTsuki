{
    lib,
    buildGoModule,
    fetchFromGitHub,
    installShellFiles,
}:

buildGoModule ( drvSelf: {

    pname = "sing-box";
    version = "1.12.1";

    src = fetchFromGitHub {
        owner = "SagerNet";
        repo = "sing-box";
        rev = "2dcb86941f5db01bbe296acae555a3b1f38c0441";
        hash = "sha256-pDwGJZYxhKdjMWl4DB4zcPJKL8qDqbXnJeHjmBhB7rY=";
    };

    vendorHash = "sha256-lehzKxjv2Tdl5mvenA0drQaX+FNaxHEfjOJZbyFpmnQ=";

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
