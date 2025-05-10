{
    lib,
    fetchFromGitHub,
    buildGoModule,
}:

buildGoModule rec {

    pname = "mihomo";
    version = "1.19.6";

    src = fetchFromGitHub {
        owner = "MetaCubeX";
        repo = "mihomo";
        rev = "v${version}";
        hash = "sha256-eVqV7Dt6V4fAT0yGF8D7niZevMmX6WggSpA5J+LU7jY=";
    };

    vendorHash = "sha256-8LATtCrQs7rDiEWKep9xPlzKw413DpS1FGJsLiWriIQ=";

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
