{
    lib,
    stdenv,
    pkgsStatic,

    fetchFromGitHub,
}:

pkgsStatic.rustTeapot.buildRustPackage rec {

    pname = "shadowsocks-rust";
    version = "1.23.1";

    src = fetchFromGitHub {
        owner = "shadowsocks";
        repo = "shadowsocks-rust";
        tag = "v${version}";
        hash = "sha256-lCm/Y0R4/Ti4Eq06/za4D2YanwQ79IkhCBK2TO9/Yfs=";
    };

    cargoHash = "sha256-//cEAeYSpsB429YaWBu+6T4dorV5OZFZuNxLgvqXxR8=";
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

