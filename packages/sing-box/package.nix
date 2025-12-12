{
    lib,
    buildGoModule,
    fetchFromGitHub,
    installShellFiles,
}:

buildGoModule ( drvSelf: {

    pname = "sing-box";
    version = "1.13.0-alpha.27-unstable-2025-12-11";

    src = fetchFromGitHub {
        owner = "SagerNet";
        repo = "sing-box";
        rev = "b2316b5c9d931e30dce143770c3019865673d101";
        hash = "sha256-4MGKTYt9QtGqdH4W1NcG5e7sgsVO+mdfle1GwCq4MvQ=";
    };

    vendorHash = "sha256-YlUdHVq+H1RDeSJjItxCMpn3EryTKSpgHdXLbS9uptI=";

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
