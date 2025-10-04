{
    lib,
    buildGoModule,
    fetchFromGitHub,
    installShellFiles,
}:

buildGoModule ( drvSelf: {

    pname = "sing-box";
    version = "1.13.0-alpha.18-unstable-2025-10-03";

    src = fetchFromGitHub {
        owner = "SagerNet";
        repo = "sing-box";
        rev = "463ae8e345c8df75010830ad7b325d93977096f3";
        hash = "sha256-TK05gbSWHEbU7zvd9brSZ2/zLssjb5kDjLimKm2Ee3Y=";
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
