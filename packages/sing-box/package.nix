{
    lib,
    buildGoModule,
    fetchFromGitHub,
    installShellFiles,
}:

buildGoModule ( drvSelf: {

    pname = "sing-box";
    version = "1.13.0-alpha.27-unstable-2025-12-12";

    src = fetchFromGitHub {
        owner = "SagerNet";
        repo = "sing-box";
        rev = "5ea761873544c6fcdc1b4976f894a3bb10959593";
        hash = "sha256-gRSy+O7xEQVGTU6AFInxXDXUR78ncUWau5+EsKgRvDk=";
    };

    vendorHash = "sha256-bBnp77IgTRG0Olrev/EmdJ+cvmkTKGs2XcAu9CQ+cro=";

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
