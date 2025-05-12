{
    lib,
    fetchFromGitHub,
    buildGoModule,
}:

buildGoModule rec {

    pname = "mihomo";
    version = "1.19.7";

    src = fetchFromGitHub {
        owner = "MetaCubeX";
        repo = "mihomo";
        rev = "v${version}";
        hash = "sha256-Ou59eDFp9A2WMRgSgAGQAA+vKBnssS5uaID8cRq9obw=";
    };

    vendorHash = "sha256-zNGnvIOjaG5PhL2BlWQW5GER0y+DRZOe0SY1WlJNruw=";

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
