{
    lib,
    buildGoModule,
    fetchFromGitHub,
}:

buildGoModule rec {

    pname = "dnscrypt-proxy";
    version = "2.1.11";

    src = fetchFromGitHub {
        owner = "DNSCrypt";
        repo = "dnscrypt-proxy";
        rev = version;
        sha256 = "sha256-/2N7RqXR6UnxPy3b6d6qdL8TPZ9ShfZPoeJic/olA4U=";
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
