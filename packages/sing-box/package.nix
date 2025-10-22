{
    lib,
    buildGoModule,
    fetchFromGitHub,
    installShellFiles,
}:

buildGoModule ( drvSelf: {

    pname = "sing-box";
    version = "1.13.0-alpha.25-unstable-2025-10-21";

    src = fetchFromGitHub {
        owner = "SagerNet";
        repo = "sing-box";
        rev = "99159b0fc3336ca11faa536b2402ca2253caedbc";
        hash = "sha256-+vjwrbo/s6Mtspmu3QJvW/xdz9XTINklp8RtLXbggh4=";
    };

    vendorHash = "sha256-QdHQ5aIdKjbi2xIAdz72kClROpIzfRpI8kfXSy5g4zc=";

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
