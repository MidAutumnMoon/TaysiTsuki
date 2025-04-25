{
    lib,
    stdenv,
    pkgsStatic,

    fetchFromGitHub,
}:

pkgsStatic.rustTeapot.buildRustPackage rec {

    pname = "shadowsocks-rust";
    version = "1.23.2";

    src = fetchFromGitHub {
        owner = "shadowsocks";
        repo = "shadowsocks-rust";
        tag = "v${version}";
        hash = "sha256-Yt2Zc+b7QpN/yO6MTg9a+7xTw9pHkYFHdq3Sz3Agdi4=";
    };

    cargoHash = "sha256-eJFXFkevSS/N4A1+tCcwWUQsklA9HUQgLHw40fW5oxM=";
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

