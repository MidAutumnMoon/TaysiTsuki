{
    lib,
    buildGoLatestModule,
    fetchFromGitHub,
    installShellFiles,
}:

buildGoLatestModule ( drvSelf: {

    pname = "sing-box";
    version = "1.13.0-alpha.6-unstable-2025-08-26";

    src = fetchFromGitHub {
        owner = "SagerNet";
        repo = "sing-box";
        rev = "51c1629da23753751796ca3666a6120d4112b49f";
        hash = "sha256-b9yr8S/XA+uRh6V4RlIOQPWG2TV0U7kUuSRXLo8i2b4=";
    };

    vendorHash = "sha256-nSGrKVG45GB4E7LqdEAqt7jSdJeYd+CHgP5Qrz1sFWE=";

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
