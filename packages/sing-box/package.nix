{
    lib,
    buildGoModule,
    fetchFromGitHub,
    installShellFiles,
}:

buildGoModule ( drvSelf: {

    pname = "sing-box";
    version = "1.13.0-alpha.27-unstable-2025-12-10";

    src = fetchFromGitHub {
        owner = "SagerNet";
        repo = "sing-box";
        rev = "8a5eba75cb176237d2c30855c26b3baee04ec388";
        hash = "sha256-n4t2q1RsPCJD1+46rfCXg6pBnBPXpHztAdS76XBoCa0=";
    };

    vendorHash = "sha256-Oads3Db/S9900qLvIOzqczJvGWWyskc39ZRVdHeQbIU=";

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
