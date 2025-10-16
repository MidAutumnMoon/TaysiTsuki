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
        rev = "609bd635450f59328e1e3e64a8ced0240e17539e";
        hash = "sha256-JquswXgl2m0r06H5csKDuWUvR95FtfkamdphNNCuNyA=";
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
