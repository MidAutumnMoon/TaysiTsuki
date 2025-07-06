{
    lib,
    stdenv,
    fetchFromGitHub,

    tsuki,

    libavif,
    libjxl,
    imagemagick,
}:

tsuki.rust.buildRustPackage rec {

    pname = "inori";
    version = "0-unstable-2025-07-04";

    src = fetchFromGitHub {
        owner = "MidAutumnMoon";
        repo = "InOri";
        rev = "f09c69f24608948eb0d1cceacc8009219b38f1c5";
        hash = "sha256-1HVYE2EAxU5yzdE85ct+V2JuhEfUypue5TuOuov5dXQ=";
    };

    cargoHash = "sha256-aE6JJmpT7Du7zqE3lIVNuncWt38Mzlj6Lmwz+fsAS1w=";
    useFetchCargoVendor = true;

    doCheck = false;

    outputs = [
        "out"
        "busnaguri"
        "lny"
    ];

    env.CFG_CJXL_PATH = lib.getExe' libjxl "cjxl";
    env.CFG_AVIFENC_PATH = lib.getExe' tsuki.libavif-hotfix "avifenc";
    env.CFG_MAGICK_PATH = lib.getExe' imagemagick "magick";

    RUSTFLAGS = with stdenv;
        lib.optional hostPlatform.isx86_64 "-Ctarget-cpu=x86-64-v3"
    ;

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

