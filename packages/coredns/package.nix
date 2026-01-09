{
    lib,
    buildGoModule,
    fetchFromGitHub,
    installShellFiles,
}:

buildGoModule rec {

    pname = "coredns";
    version = "1.14.0";

    src = fetchFromGitHub {
        owner = "coredns";
        repo = "coredns";
        rev = "v${version}";
        sha256 = "sha256-P+DKaKVyNMMXrSorXfl2YqoemCIHxCtT5SCDteGsDEk=";
    };

    vendorHash = "sha256-DhVj9Ott0hvUYRsnFkFwiIeUmq2rBeu2UaZXCvZby2U=";

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
