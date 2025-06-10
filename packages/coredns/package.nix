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

    nativeBuildInputs = [ installShellFiles ];

    preBuild = ''
        GOOS= GOARCH= go generate
    '';

    postPatch = /*bash*/ ''
        substituteInPlace test/file_cname_proxy_test.go \
            --replace-fail "TestZoneExternalCNAMELookupWithProxy" \
                      "SkipZoneExternalCNAMELookupWithProxy"

        substituteInPlace test/readme_test.go \
            --replace-fail "TestReadme" "SkipReadme"
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
