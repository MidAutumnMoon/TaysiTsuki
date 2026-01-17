{
    lib,
    buildGoModule,
    fetchFromGitHub,
    installShellFiles,
}:

buildGoModule rec {

    pname = "coredns";
    version = "1.14.1";

    src = fetchFromGitHub {
        owner = "coredns";
        repo = "coredns";
        rev = "v${version}";
        sha256 = "sha256-WcRX2BCWIQ8e0FYCIAzCdexz+Nl+/kKicQkhEw2AVMs=";
    };

    vendorHash = "sha256-MbuG9gb4P3yTtBT+utTC/sFsETEvPHbv8Rf5Vgjx9w8=";

    outputs = [
        "out"
        "man"
    ];

    env.GOAMD64 = "v3";
    env.CGO_ENABLED = 0;

    doCheck = false;

    nativeBuildInputs = [ installShellFiles ];

    preBuild = ''
        GOOS= GOARCH= go generate -v -n -x -mod=readonly
    '';

    postInstall = ''
        installManPage man/*
    '';

    meta = with lib; {
        homepage = "https://coredns.io";
        description = "DNS server that runs middleware";
        mainProgram = "coredns";
        license = licenses.asl20;
    };

}
