{
    lib,
    buildGoLatestModule,
    fetchFromGitHub,
    installShellFiles,
}:

buildGoLatestModule ( drvSelf: {

    pname = "sing-box";
    version = "1.13.0-alpha.2-unstable-2025-08-18";

    src = fetchFromGitHub {
        owner = "SagerNet";
        repo = "sing-box";
        rev = "eca9ce5cca7f2eeddccdf30907921e5a6b361d67";
        hash = "sha256-Frc4QdJC0iKUM+iZUEgw6ZUL9Lmkbx4Fi8V1t7tfAC4=";
    };

    vendorHash = "sha256-kXyiZTLk18pdDGugc77wFBKQQJ4N92gUmIksovLxtFc=";

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
