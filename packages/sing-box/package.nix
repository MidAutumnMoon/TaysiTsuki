{
    lib,
    buildGoModule,
    fetchFromGitHub,
    installShellFiles,
    coreutils,
}:

buildGoModule ( drvSelf: {

    pname = "sing-box";
    version = "1.12.0-beta.33-unstable-2025-07-12";

    src = fetchFromGitHub {
        owner = "SagerNet";
        repo = "sing-box";
        rev = "b3c11109e0ba11ea849f2fc7f30b768727d7a722";
        hash = "sha256-ocEJrZrRth6Yb3YOAgI2JGNGukneaXYeuGcescjpZg4=";
    };

    vendorHash = "sha256-Hle1Jdn3iXPtT+vV3qkoWyEjvj00NMdGnG7HkpeXFaM=";

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

        substituteInPlace release/config/sing-box{,@}.service \
            --replace-fail "/usr/bin/sing-box" "$out/bin/sing-box" \
            --replace-fail "/bin/kill" "${coreutils}/bin/kill"
            install -Dm444 -t "$out/lib/systemd/system/" release/config/sing-box{,@}.service
    '';

    meta = {
        homepage = "https://sing-box.sagernet.org";
        description = "Universal proxy platform";
        license = lib.licenses.gpl3Plus;
        mainProgram = "sing-box";
    };
} )
