{
    lib,
    buildGoModule,
    fetchFromGitHub,
    installShellFiles,
}:

buildGoModule ( drvSelf: {

    pname = "sing-box";
    version = "1.13.0-alpha.22-unstable-2025-10-17";

    src = fetchFromGitHub {
        owner = "SagerNet";
        repo = "sing-box";
        rev = "b798643fecd631db5e3fdc270c1495c326099982";
        hash = "sha256-7Z6IbU3gjXXVJxLp+ugqNZsvaPlrTRMIw8kf0IIofIA=";
    };

    vendorHash = "sha256-R2ykxMdQ2/S62t76xVfeKxj1i6u/+uytKnClwB+sK+o=";

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
