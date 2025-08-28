{
    lib,
    buildGoLatestModule,
    fetchFromGitHub,
    installShellFiles,
}:

buildGoLatestModule ( drvSelf: {

    pname = "sing-box";
    version = "1.13.0-alpha.8-unstable-2025-08-28";

    src = fetchFromGitHub {
        owner = "SagerNet";
        repo = "sing-box";
        rev = "d03b4eaf0a9f10cbac96646698a19029e9da795f";
        hash = "sha256-4LtLeh+1fiCAwgHZK48YMHJOivFj3OGJUpWdlpK7PFE=";
    };

    vendorHash = "sha256-vzjM7jOiOGyY+ucDABzWWo5a+W1+msnHsdMxHi7yb1A=";

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
