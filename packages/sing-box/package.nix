{
    lib,
    buildGoModule,
    fetchFromGitHub,
    installShellFiles,
}:

buildGoModule ( drvSelf: {

    pname = "sing-box";
    version = "1.13.0-alpha.23-unstable-2025-10-21";

    src = fetchFromGitHub {
        owner = "SagerNet";
        repo = "sing-box";
        rev = "da67913f3ba3ca20b52f8919e59f0d2bddc465f2";
        hash = "sha256-HjaOWoCeZiba+/5TJ/IfQdMx3uFgZeV+wTguTU4AeO4=";
    };

    vendorHash = "sha256-Mq3s9hLR6OhHAaobGAYliBcMb8JdhNG3miUerW6nMfY=";

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
