{
    lib,
    buildGoLatestModule,
    fetchFromGitHub,
    installShellFiles,
}:

buildGoLatestModule ( drvSelf: {

    pname = "sing-box";
    version = "1.13.0-alpha.15-unstable-2025-09-15";

    src = fetchFromGitHub {
        owner = "SagerNet";
        repo = "sing-box";
        rev = "d663278d664b1e056e9c16e09d3081468134fe72";
        hash = "sha256-qgktGKV5cWSeTHMWYelZb2qpzw2XPw620xG80xBrwFk=";
    };

    vendorHash = "sha256-2rkMwTnKzmIfb3O+OwsSuWJqU+WT7QFrCiPQHx2AXRI=";

    subPackages = [
        "cmd/sing-box"
    ];

    tags = [
        "with_quic"
        "with_clash_api"
        "with_utls"
    ];

    ldflags = [
        "-s"
        "-X=github.com/sagernet/sing-box/constant.Version=${drvSelf.version}"
        "-checklinkname=0"
    ];

    env.GOAMD64 = "v3";
    env.CGO_ENABLED = 0;
    env.GOEXPERIMENT = "greenteagc";

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
