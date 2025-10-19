{
    lib,
    buildGoModule,
    fetchFromGitHub,
    installShellFiles,
}:

buildGoModule ( drvSelf: {

    pname = "sing-box";
    version = "1.13.0-alpha.23-unstable-2025-10-18";

    src = fetchFromGitHub {
        owner = "SagerNet";
        repo = "sing-box";
        rev = "8e9fb1c9ad1b3c95c620a457a2cd6782dd0091ad";
        hash = "sha256-Kxye+xugtVcRIQ6MMKXUopN4KJxg8bbEin9JR/dwR+U=";
    };

    vendorHash = "sha256-IuvLoVUAT3UMNf7rttdK0a+1YryNbNGxC1tDJxBDkmA=";

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
