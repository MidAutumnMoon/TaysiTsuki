{
    lib,
    buildGoModule,
    fetchFromGitHub,
    installShellFiles,
}:

buildGoModule ( drvSelf: {

    pname = "sing-box";
    version = "1.12.0-beta.35";

    src = fetchFromGitHub {
        owner = "SagerNet";
        repo = "sing-box";
        rev = "837f6c44c22fa03435995623d1c4ce6f4473a67b";
        hash = "sha256-cIkanMoGVHQPk9unPFFioKRT7dbWDbGw6Qn1OxcKC/Q=";
    };

    vendorHash = "sha256-0lBe2kCnr+A6z5sInfMUurqXyKRMEJTSFPTi0Z7P498=";

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
