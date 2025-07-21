{
    lib,
    buildGoModule,
    fetchFromGitHub,
    installShellFiles,
}:

buildGoModule rec {

    pname = "coredns";
    version = "1.12.2";

    src = fetchFromGitHub {
        owner = "coredns";
        repo = "coredns";
        rev = "v${version}";
        sha256 = "sha256-P4GhWrEACR1ZhNhGAoXWvNXYlpwnm2dz6Ggqv72zYog=";
    };

    vendorHash = "sha256-u73R+GwQEO6x1oSSoweyKyhfRQetsjOgDk1Bilep0n8=";

    outputs = [
        "out"
        "man"
    ];

    env.GOAMD64 = "v3";
    env.CGO_ENABLED = 0;

    doCheck = false;

    nativeBuildInputs = [ installShellFiles ];

    preBuild = ''
        GOOS= GOARCH= go generate -v -n -x
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
