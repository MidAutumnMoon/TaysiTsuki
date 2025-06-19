{
    lib,
    stdenv,
    fetchFromGitHub,

    tsuki,

    libavif,
    libjxl,
    imagemagick,

    writableTmpDirAsHomeHook,
}:

tsuki.rust.buildRustPackage rec {

    pname = "inori";
    version = "0-unstable-2025-06-19";

    src = fetchFromGitHub {
        owner = "MidAutumnMoon";
        repo = "InOri";
        rev = "7f071172de6f31b922e1d5c2dc6476cab7c8f898";
        hash = "sha256-fWO5XwiWnlE92R7Zv0W+opxX1LwqyLS+eQQiN+Z8otc=";
    };

    cargoHash = "sha256-73mH9YOLX15pvXmikyepT8PDcci3knLE+xacDhdKvDM=";
    useFetchCargoVendor = true;

    outputs = [
        "out"
        "busnaguri"
        "lny"
    ];

    nativeCheckInputs = [
        writableTmpDirAsHomeHook
    ];

    env.CFG_CJXL_PATH = lib.getExe' libjxl "cjxl";
    env.CFG_AVIFENC_PATH = lib.getExe' libavif "avifenc";
    env.CFG_MAGICK_PATH = lib.getExe' imagemagick "magick";

    RUSTFLAGS = with stdenv;
        lib.optional hostPlatform.isx86_64 "-Ctarget-cpu=x86-64-v3"
    ;

    preCheck = ''
        export XDG_RUNTIME_DIR="$HOME/rt"
        export XDG_DATA_HOME="$HOME/data"
        export XDG_CONFIG_HOME="$HOME/cfg"
        export XDG_CACHE_HOME="$HOME/cache"
        export XDG_STATE_HOME="$HOME/st"
    '';

    postFixup = /*sh*/ ''
        # coruma
        ln -sv "$out/bin/coruma-reverse" "$out/bin/,?"

        # busnaguri
        declare -r BUSN_LIBEXEC_DIR="$busnaguri/libexec/inori"
        declare -r BUSN_BIN="$BUSN_LIBEXEC_DIR/busnaguri"
        declare -r BUSN_DBUS_DIR="$busnaguri/share/dbus-1/services"

        mkdir -vp "$BUSN_LIBEXEC_DIR"
        mkdir -pv "$( dirname "$BUSN_BIN" )"
        mkdir -pv "$BUSN_DBUS_DIR"

        mv -v "$out/bin/busnaguri" "$BUSN_BIN"

        cat <<-DOSINI > "$BUSN_DBUS_DIR/${passthru.busnaguriData.service}.service"
        [D-BUS Service]
        Name = ${passthru.busnaguriData.service}
        Exec = $BUSN_BIN
        DOSINI

        # lny
        declare -r LNY_BIN_DIR="$lny/bin"
        mkdir -pv "$LNY_BIN_DIR"
        mv -v "$out/bin/lny" -t "$LNY_BIN_DIR"
    '';

    passthru = {
        busnaguriData = {
            service = "im._418.Busnaguri";
            objectPath = "/Naguru";
            interface = "im._418.busnaguri";
        };
    };

    meta = {
        homepage = "https://github.com/MidAutumnMoon/InOri";
        license = lib.licenses.gpl3Plus;
    };

}

