{
    lib,
    buildGoModule,
    fetchFromGitHub,
    installShellFiles,
}:

buildGoModule rec {

    pname = "coredns";
    version = "1.11.3";

    src = fetchFromGitHub {
        owner = "coredns";
        repo = "coredns";
        rev = "v${version}";
        sha256 = "sha256-8LZMS1rAqEZ8k1IWSRkQ2O650oqHLP0P31T8oUeE4fw=";
    };

    vendorHash = "sha256-D2YvfPvzOE3cdQVeOde/C+TYISHtePI3f8p6UJfYlpo=";

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
