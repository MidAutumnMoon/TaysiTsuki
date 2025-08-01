{
    lib,
    buildGoModule,
    fetchFromGitHub,
    installShellFiles,
}:

buildGoModule ( drvSelf: {

    pname = "sing-box";
    version = "1.12.0-rc.4";

    src = fetchFromGitHub {
        owner = "SagerNet";
        repo = "sing-box";
        rev = "94d9c181d9f950ebc95a198eccb325815c09eece";
        hash = "sha256-IOGhdkpUCf+Oppvm30O3XIVRaedEGaJY44MOcd45lBI=";
    };

    vendorHash = "sha256-lehzKxjv2Tdl5mvenA0drQaX+FNaxHEfjOJZbyFpmnQ=";

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
    '';

    meta = {
        homepage = "https://sing-box.sagernet.org";
        description = "Universal proxy platform";
        license = lib.licenses.gpl3Plus;
        mainProgram = "sing-box";
    };
} )
