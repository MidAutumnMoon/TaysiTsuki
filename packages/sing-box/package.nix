{
    lib,
    buildGoLatestModule,
    fetchFromGitHub,
    installShellFiles,
}:

buildGoLatestModule ( drvSelf: {

    pname = "sing-box";
    version = "1.13.0-alpha.4-unstable-2025-08-20";

    src = fetchFromGitHub {
        owner = "SagerNet";
        repo = "sing-box";
        rev = "3572acf26645ff4fd690e93120abe98fa963d8de";
        hash = "sha256-eUMKghkpBchXHGUNxmcA0z+EKPSShB5CPZKBwBAVmEA=";
    };

    vendorHash = "sha256-Y/UP2rbee4WSctelk9QddMXciucz5dNLOLDDWtEFfLU=";

    subPackages = [
        "cmd/sing-box"
    ];

    tags = [
        "with_quic"
        "with_clash_api"
    ];

    ldflags = [
        "-s"
        "-X=github.com/sagernet/sing-box/constant.Version=${drvSelf.version}"
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
