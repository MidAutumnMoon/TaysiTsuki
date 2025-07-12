{
    lib,
    buildGoModule,
    fetchFromGitHub,
    installShellFiles,
    coreutils,
}:

buildGoModule ( drvSelf: {

    pname = "sing-box";
    version = "1.12.0-beta.31";

    src = fetchFromGitHub {
        owner = "SagerNet";
        repo = "sing-box";
        rev = "989034b8f7f6672e2dde060649b17cc29fceff91";
        hash = "sha256-WwwZePdEokhLIOMJLSZV5oIEuufr+1hPaiONYaz+Nzk=";
    };

    vendorHash = "sha256-t76QBdgTprVM5g6ytl0nG+daO6WEnI1Q5gA3bPMRR9Y=";

    subPackages = [
        "cmd/sing-box"
    ];

    tags = [
        "with_quic"
        "with_clash_api"
        "with_utls"
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
