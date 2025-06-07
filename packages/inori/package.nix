{
    lib,
    stdenv,
    fetchFromGitHub,

    tsuki,

    libavif,
    libjxl,
    imagemagick,
}:

tsuki.rust.buildRustPackage {

    pname = "inori";
    version = "0-unstable-2025-06-07";

    src = fetchFromGitHub {
        owner = "MidAutumnMoon";
        repo = "InOri";
        rev = "79f28f2fb1540cf3c8932d793dd403070a53fda0";
        hash = "sha256-0MCHlMfKr5I3CmKaccwF8tVfHolAT75gWH3VAgrPwf4=";
    };

    cargoHash = "sha256-WFaG6ThAat1h6R8lsXXQZQFuaxGueFgN0guc9lMJEAA=";
    useFetchCargoVendor = true;

    env.CFG_CJXL_PATH = lib.getExe' libjxl "cjxl";
    env.CFG_AVIFENC_PATH = lib.getExe' libavif "avifenc";
    env.CFG_MAGICK_PATH = lib.getExe' imagemagick "magick";

    RUSTFLAGS = with stdenv;
        lib.optional hostPlatform.isx86_64 "-Ctarget-cpu=x86-64-v3"
    ;

    postFixup = ''
        ln -sv "$out/bin/coruma-reverse" "$out/bin/,?"

        declare LIBEXEC_DIR="$out/libexec/inori"
        declare DBULUNR="$LIBEXEC_DIR/dbulunr"

        mkdir -p "$LIBEXEC_DIR"
        mv -v "$out/bin/dbulunr" "$DBULUNR"

        declare -r DBUS_DIR="$out/share/dbus-1/services"
        mkdir -pv "$DBUS_DIR"

        cat <<-DOSINI > "$DBUS_DIR/im._418.dbulunr.service"
        [D-BUS Service]
        Name = im._418.Dbulunr
        Exec = $DBULUNR
        DOSINI
    '';

    meta = {
        homepage = "https://github.com/MidAutumnMoon/InOri";
        license = lib.licenses.gpl3Plus;
    };

}

