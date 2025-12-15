{
    lib,
    buildGoModule,
    fetchFromGitHub,
    installShellFiles,
}:

buildGoModule ( drvSelf: {

    pname = "sing-box";
    version = "1.13.0-alpha.28-unstable-2025-12-15";

    src = fetchFromGitHub {
        owner = "SagerNet";
        repo = "sing-box";
        rev = "23ce4e616fd531af6747491ad4809a3346587756";
        hash = "sha256-SWiVbzVS+gfxqgz1vFSShp5rE536hNCI7arrhvJO2Cs=";
    };

    vendorHash = "sha256-jDYTwTq9QS2hDSw6PMybUeJWTioL2MZvauUaZRCLKo8=";

    subPackages = [
        "cmd/sing-box"
    ];

    tags = [
        "with_acme"
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
