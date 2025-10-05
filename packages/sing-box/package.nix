{
    lib,
    buildGoModule,
    fetchFromGitHub,
    installShellFiles,
}:

buildGoModule ( drvSelf: {

    pname = "sing-box";
    version = "1.13.0-alpha.19-unstable-2025-10-05";

    src = fetchFromGitHub {
        owner = "SagerNet";
        repo = "sing-box";
        rev = "36836624f9b0c6eb35825753977a7644dfa43304";
        hash = "sha256-j5tQy5+TKA2d0B18YY0n8ZsH2V9XPYa2Nvbjhr+DxUw=";
    };

    vendorHash = "sha256-MBaxyfEWShRB1w79SMNMLz2WOR4fBbIpfufctMQRF9Q=";

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
