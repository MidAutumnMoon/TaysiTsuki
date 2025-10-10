{
    lib,
    buildGoModule,
    fetchFromGitHub,
    installShellFiles,
}:

buildGoModule ( drvSelf: {

    pname = "sing-box";
    version = "1.13.0-alpha.21-unstable-2025-10-10";

    src = fetchFromGitHub {
        owner = "SagerNet";
        repo = "sing-box";
        rev = "43a3beb98851ad5e27e60042ea353b63c7d77448";
        hash = "sha256-SxIytB9jTF4s3cifv0bQaNWxMCZUH5Z70TaSnJXji8E=";
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
