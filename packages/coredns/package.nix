{
    lib,
    buildGoModule,
    fetchFromGitHub,
    installShellFiles,
}:

buildGoModule rec {

    pname = "coredns";
    version = "1.14.7";

    src = fetchFromGitHub {
        owner = "coredns";
        repo = "coredns";
        rev = "v${version}";
        sha256 = "sha256-83GPahSGGCckvb9uqz7aWzMDSDNfHfr69Tihvu/OSpY=";
    };

    proxyVendor = true;
    vendorHash = "sha256-ccRp0mP0clB1QmoTQDfFiOtc0OeZNKxrQUn974bUV0U=";

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
