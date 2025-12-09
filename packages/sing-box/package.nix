{
    lib,
    buildGoModule,
    fetchFromGitHub,
    installShellFiles,
}:

buildGoModule ( drvSelf: {

    pname = "sing-box";
    version = "1.13.0-alpha.27-unstable-2025-12-09";

    src = fetchFromGitHub {
        owner = "SagerNet";
        repo = "sing-box";
        rev = "b4247571c6e0d754161a21d82205c2cf37b219b0";
        hash = "sha256-CFoWnfeyDY5vOY+2pkAnaM0x3r+aO4yirblc3MDZIzs=";
    };

    vendorHash = "sha256-XoAfWJgCtiFGAYBBBKe4b56o6tYl78/g/id8tKRC9MA=";

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
