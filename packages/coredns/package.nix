{
    lib,
    buildGoModule,
    fetchFromGitHub,
    installShellFiles,
}:

buildGoModule rec {

    pname = "coredns";
    version = "1.14.3";

    src = fetchFromGitHub {
        owner = "coredns";
        repo = "coredns";
        rev = "v${version}";
        sha256 = "sha256-Uk4oWsUxaGdLQzX5JywYzi7pmQHGo06uQdLeOkP4U/s=";
    };

    proxyVendor = true;
    vendorHash = "sha256-iqoJoo6dYS03t+O7RXjEpcT0VC6pBYMBrEr7K6otlsY=";

    outputs = [
        "out"
        "man"
    ];

    env.GOAMD64 = "v3";
    env.CGO_ENABLED = 0;

    doCheck = false;

    nativeBuildInputs = [ installShellFiles ];

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
