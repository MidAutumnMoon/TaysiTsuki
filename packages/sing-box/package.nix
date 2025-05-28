{
    lib,
    buildGoModule,
    fetchFromGitHub,
    installShellFiles,
    coreutils,
    nix-update-script,
    nixosTests,
}:

buildGoModule ( drvSelf: {

    pname = "sing-box";
    version = "1.11.11";

    src = fetchFromGitHub {
        owner = "SagerNet";
        repo = "sing-box";
        tag = "v${drvSelf.version}";
        hash = "sha256-hdYYjKBXnTqScYTUCfMmXozDD8GtIorLXnsU2Fmwg/c=";
    };

    vendorHash = "sha256-/0pwsZbMbyAFXCrukbNf2RmQjQJ1E/ZUwzrC+5NEZcc=";

    subPackages = [
        "cmd/sing-box"
    ];

    tags = [
        "with_quic"
        "with_wireguard"
        "with_utls"
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
