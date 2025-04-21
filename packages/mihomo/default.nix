{
    lib,
    fetchFromGitHub,
    buildGoModule,
}:

buildGoModule rec {

    pname = "mihomo";
    version = "1.19.5";

    src = fetchFromGitHub {
        owner = "MetaCubeX";
        repo = "mihomo";
        rev = "v${version}";
        hash = "sha256-eINcvVnWMDbviqNpD+SmtDYVQjLZgjaAdX9NrRAf0Ww=";
    };

    vendorHash = "sha256-xGaJ9iAP6Q8L6oC6LqEwi69Bd7H+bjSykGXckkZL92k=";

    excludedPackages = [ "./test" ];

    env.GOAMD64 = "v3";
    env.CGO_ENABLED = 0;

    ldflags = [
        "-s" "-w"
        "-X github.com/metacubex/mihomo/constant.Version=${version}"
    ];

    tags = [
        "no_fake_tcp"
    ];

    # network required
    doCheck = false;

    meta = with lib; {
        description = "Rule-based tunnel in Go";
        homepage = "https://github.com/MetaCubeX/mihomo/tree/Alpha";
        license = licenses.gpl3Only;
        mainProgram = "mihomo";
    };

}
