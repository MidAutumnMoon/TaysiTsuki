{
    lib,
    stdenv,
    pkgsStatic,

    fetchFromGitHub,
}:

pkgsStatic.tsuki.rust.buildRustPackage rec {

    pname = "shadowsocks-rust";
    version = "1.23.3";

    src = fetchFromGitHub {
        owner = "shadowsocks";
        repo = "shadowsocks-rust";
        tag = "v${version}";
        hash = "sha256-gUCDHk6Z3w3ajtYV8s0TXXnJCiHhOdMZRcIK4uPnQ2M=";
    };

    cargoHash = "sha256-DsdVvYznh9i3d3UdcKOCYRoisP8BAJ6XLV2JbFhEr5M=";
    useFetchCargoVendor = true;

    doCheck = false;

    stripAllList = [ "bin" ];

    RUSTFLAGS = with stdenv;
        lib.optional hostPlatform.isx86_64 "-Ctarget-cpu=x86-64-v3"
    ;

    env.CARGO_PROFILE_RELEASE_LTO = "thin";

    buildNoDefaultFeatures = true;

    buildFeatures = [
        "service"
        "hickory-dns"
        "local-http"
        "multi-threaded"
        "aead-cipher-2022"
        "logging"
        "security-replay-attack-detect"
        "jemalloc"
    ];

    meta = {
        homepage = "https://github.com/shadowsocks/shadowsocks-rust";
        license = lib.licenses.mit;
    };

}

