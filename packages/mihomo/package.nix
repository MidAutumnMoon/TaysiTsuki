{
    lib,
    fetchFromGitHub,
    buildGoModule,
}:

buildGoModule rec {

    pname = "mihomo";
    version = "1.19.8";

    src = fetchFromGitHub {
        owner = "MetaCubeX";
        repo = "mihomo";
        rev = "v${version}";
        hash = "sha256-C8g2KhhXY11bqGKthNgiqdZwxoPVPhflhkh+X6JU33I=";
    };

    vendorHash = "sha256-j97UFlcN8SfY6nireI6NDw8UcQuxyH34gue1Ywf25Yg=";

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
