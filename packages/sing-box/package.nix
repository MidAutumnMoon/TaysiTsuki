{
    lib,
    buildGoLatestModule,
    fetchFromGitHub,
    installShellFiles,
}:

buildGoLatestModule ( drvSelf: {

    pname = "sing-box";
    version = "1.13.0-alpha.18-unstable-2025-09-23";

    src = fetchFromGitHub {
        owner = "SagerNet";
        repo = "sing-box";
        rev = "5dd435862959e9502a8088c56883564a51cb2ab5";
        hash = "sha256-4njtNjiQ9rjbF2iyiIGTxWqrdg+l+OBzuFOvygfNvgE=";
    };

    vendorHash = "sha256-UC0RV5qj0OvGg4DinLq5a/P1B0xRgFJEt62xr24aKKo=";

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
