{
    lib,
    buildGoModule,
    fetchFromGitHub,
    installShellFiles,
}:

buildGoModule rec {

    pname = "coredns";
    version = "1.12.4";

    src = fetchFromGitHub {
        owner = "coredns";
        repo = "coredns";
        rev = "v${version}";
        sha256 = "sha256-dK5/kJRqo2Z2kPkzLqzp7NU0GlRHz1/4zXtdP6SeSiI=";
    };

    vendorHash = "sha256-rk03J3Ta/k2U876J+V4eEgoL2OotxLYh0tN3k35gIKg=";

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
