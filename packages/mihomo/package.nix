{
    lib,
    fetchFromGitHub,
    buildGoModule,
}:

buildGoModule rec {

    pname = "mihomo";
    version = "1.19.9";

    src = fetchFromGitHub {
        owner = "MetaCubeX";
        repo = "mihomo";
        rev = "v${version}";
        hash = "sha256-T1tg4sAR7OY3N6OheUySyQ0HLXYUBTLjeWx3qxHsb30=";
    };

    vendorHash = "sha256-+7D2XAmN2AF2N1tmE1O7378duQYX5fgkUDxeO4n7Glk=";

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
