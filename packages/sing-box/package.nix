{
    lib,
    buildGoModule,
    fetchFromGitHub,
    installShellFiles,
}:

buildGoModule ( drvSelf: {

    pname = "sing-box";
    version = "1.13.0-alpha.27-unstable-2025-12-07";

    src = fetchFromGitHub {
        owner = "SagerNet";
        repo = "sing-box";
        rev = "76d447d7d99d08b8f3110d9127a4d3d62526e659";
        hash = "sha256-TU8WAlsnmC3D3o+JTwxrg3zbdkorQMpmsUdyUka1nck=";
    };

    vendorHash = "sha256-6HvfxQ82SEVUCLl/mXx3u4X1kpQWYl8zMo338v+DdKc=";

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
