{
    lib,
    buildGoModule,
    fetchFromGitHub,
    installShellFiles,
}:

buildGoModule ( drvSelf: {

    pname = "sing-box";
    version = "1.13.0-alpha.28-unstable-2025-12-13";

    src = fetchFromGitHub {
        owner = "SagerNet";
        repo = "sing-box";
        rev = "8769d1344b120bb2a422c5e00d03ca11052b8b8a";
        hash = "sha256-vxojLIAz8OlI/qr1E+sr+mag2CAJ2k8C5Bwi9dqpKYc=";
    };

    vendorHash = "sha256-AMsyZWuX9fCz121DdqL+r0D2P9iAXhA+Slm27o4wLis=";

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
