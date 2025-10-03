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
    version = "0-unstable-2025-08-01";

    src = fetchFromGitHub {
        owner = "MidAutumnMoon";
        repo = "InOri";
        rev = "162dd2a817f14090c53ff604dcf42e1612a16a46";
        hash = "sha256-iFnB7UUQHDPNbG2JWFDi4FZt5oNgeVwoEK/O2G5YgYg=";
    };

    cargoHash = "sha256-JhaXWKPQPE+q4RV5wwxhdTX8uSgUcQ3kr012/GkEovQ=";

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
        lib.optional hostPlatform.isx86_64 "-Ctarget-cpu=x86-64-v2"
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

