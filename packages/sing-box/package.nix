{
    lib,
    buildGoModule,
    fetchFromGitHub,
    installShellFiles,
}:

buildGoModule ( drvSelf: {

    pname = "sing-box";
    version = "1.13.0-alpha.27-unstable-2025-12-10";

    src = fetchFromGitHub {
        owner = "SagerNet";
        repo = "sing-box";
        rev = "16ad84c0f83786ae3e3f077f2a45279ecdf02e92";
        hash = "sha256-Jmc/qlC8aD54Mq8+zsI4YDe4BzkphqeLUPFpjutZW5Y=";
    };

    vendorHash = "sha256-D0dwLSNe7BrHqrp70zskPuzZ2B4f59+ELniKmsZuqnA=";

    subPackages = [
        "cmd/sing-box"
    ];

    tags = [
        "with_acme"
        "with_quic"
        "with_clash_api"
        "with_utls"
        "badlinkname"
    ];

    ldflags = [
        "-s"
        "-X=github.com/sagernet/sing-box/constant.Version=${drvSelf.version}"
        "-checklinkname=0"
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
