{
    lib,
    buildGoModule,
    fetchFromGitHub,
    installShellFiles,
}:

buildGoModule ( drvSelf: {

    pname = "sing-box";
    version = "1.13.0-alpha.27-unstable-2025-12-06";

    src = fetchFromGitHub {
        owner = "SagerNet";
        repo = "sing-box";
        rev = "7c6d6f249c02fb48c16441683efd893dc5f1c642";
        hash = "sha256-1KPiHqjNXQyihjEt23kpuJfWTthD02uNoMx4CqVAkuc=";
    };

    vendorHash = "sha256-Jv2d23ROqpX5RiJt6t0YzCRRm3FOkWLipFMriW3vNig=";

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
