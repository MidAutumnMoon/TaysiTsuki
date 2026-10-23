{
    lib,
    buildGoLatestModule,
    fetchFromGitHub,
}:

buildGoLatestModule rec {

    pname = "dnscrypt-proxy";
    version = "2.1.20";

    src = fetchFromGitHub {
        owner = "DNSCrypt";
        repo = "dnscrypt-proxy";
        rev = version;
        sha256 = "sha256-mNOtMC5GXIE/SSPNyuEBbXQvYj4vvVAc83cQ2jeT978=";
    };

    vendorHash = null;

    doCheck = false;

    env.GOAMD64 = "v3";
    env.CGO_ENABLED = 0;

    meta = with lib; {
        description = "Tool that provides secure DNS resolution";
        license = licenses.isc;
        homepage = "https://dnscrypt.info/";
        mainProgram = "dnscrypt-proxy";
        platforms = with platforms; unix;
    };
}
