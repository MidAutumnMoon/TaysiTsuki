{
    lib,
    buildGoModule,
    fetchFromGitHub,
    installShellFiles,
}:

buildGoModule ( drvSelf: {

    pname = "sing-box";
    version = "1.13.0-alpha.22-unstable-2025-10-14";

    src = fetchFromGitHub {
        owner = "SagerNet";
        repo = "sing-box";
        rev = "7b5fc3d6df29a379fe7b47404e4908f2084fad36";
        hash = "sha256-U7+UiflnmDOVBbvG49d6OHymcWOdo4CHAG6FmopTK5U=";
    };

    vendorHash = "sha256-DsURHNN0DBTqgn6VUaWYj2Wa+BQeMSwoEHLe1JROpao=";

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
