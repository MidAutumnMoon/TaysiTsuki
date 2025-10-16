{
    lib,
    buildGoModule,
    fetchFromGitHub,
    installShellFiles,
}:

buildGoModule ( drvSelf: {

    pname = "sing-box";
    version = "1.13.0-alpha.22-unstable-2025-10-16";

    src = fetchFromGitHub {
        owner = "SagerNet";
        repo = "sing-box";
        rev = "ab7df4d47df69a8304768f8365603d73342098f6";
        hash = "sha256-8EdAIjfjayAeSDGxL4hwXBjta4miy9+2cnu4cgCtN08=";
    };

    vendorHash = "sha256-Avlu3QbF7k8luLt6YAEBotSiidzIAilhl/J2hGlgFh8=";

    subPackages = [
        "cmd/sing-box"
    ];

    tags = [
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
