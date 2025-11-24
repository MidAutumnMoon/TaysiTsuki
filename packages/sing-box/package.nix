{
    lib,
    buildGoModule,
    fetchFromGitHub,
    installShellFiles,
}:

buildGoModule ( drvSelf: {

    pname = "sing-box";
    version = "1.13.0-alpha.27-unstable-2025-11-23";

    src = fetchFromGitHub {
        owner = "SagerNet";
        repo = "sing-box";
        rev = "877e7a89f0137b588d2d7f2576afe3d643676748";
        hash = "sha256-dxM8K8SCJS4gHa7n/IpMhRjSuMs2aWK5eA6dlviNyV8=";
    };

    vendorHash = "sha256-OxhwP7uYXpnPFkZBFKw+4fw+gkufHNAUV3xZ4VFj2yQ=";

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
