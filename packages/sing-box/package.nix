{
    lib,
    buildGoModule,
    fetchFromGitHub,
    installShellFiles,
}:

buildGoModule ( drvSelf: {

    pname = "sing-box";
    version = "1.13.0-alpha.27-unstable-2025-10-27";

    src = fetchFromGitHub {
        owner = "SagerNet";
        repo = "sing-box";
        rev = "84ceb90eeb36ec25aadcbedd614373850d9c4c5a";
        hash = "sha256-0iKUTfSX4oijjl3AQb4k5voWII3y3adYw6yYpd+Qdd8=";
    };

    vendorHash = "sha256-OxhwP7uYXpnPFkZBFKw+4fw+gkufHNAUV3xZ4VFj2yQ=";

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
