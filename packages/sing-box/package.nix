{
    lib,
    buildGoModule,
    fetchFromGitHub,
    installShellFiles,
}:

buildGoModule ( drvSelf: {

    pname = "sing-box";
    version = "1.13.0-alpha.27-unstable-2025-12-12";

    src = fetchFromGitHub {
        owner = "SagerNet";
        repo = "sing-box";
        rev = "6920022ea81c14a1209df092e0671f85aa8e50f7";
        hash = "sha256-X9e3Nfa4bSm+Pg3ChW0PeqnnjzqbBgJprJKl84XFV2o=";
    };

    vendorHash = "sha256-RWCEVQ6ZDKAENnY/is6F2Adf8LOMlZ3seUNFWwlutu4=";

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
