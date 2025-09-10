{
    lib,
    buildGoLatestModule,
    fetchFromGitHub,
    installShellFiles,
}:

buildGoLatestModule ( drvSelf: {

    pname = "sing-box";
    version = "1.13.0-alpha.10-unstable-2025-09-10";

    src = fetchFromGitHub {
        owner = "SagerNet";
        repo = "sing-box";
        rev = "1ea23490b5e53337efc56adaf74f21c5a52e7569";
        hash = "sha256-MyM5DcnIxmjLj82wBZdKKpHCxKvQvFocoDC51EdDLuo=";
    };

    vendorHash = "sha256-G3lQywLMa247k4/MB82HCNujka6GKYhaQTJGoYwTt2w=";

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
