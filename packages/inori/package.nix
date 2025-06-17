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
    version = "0-unstable-2025-06-11";

    src = fetchFromGitHub {
        owner = "MidAutumnMoon";
        repo = "InOri";
        rev = "a75f8ae4200b9e2944f5f8cc08b849106d4e14ce";
        hash = "sha256-kJrUtVuxDhvxuXPI7wQLwClDoY2cV9GtZLt4Ly8Fx/o=";
    };

    cargoHash = "sha256-4afFrh83PzBq5oSjmFH0Nd+yGquJH7BT3RniGMZoJmM=";
    useFetchCargoVendor = true;

    env.CFG_CJXL_PATH = lib.getExe' libjxl "cjxl";
    env.CFG_AVIFENC_PATH = lib.getExe' libavif "avifenc";
    env.CFG_MAGICK_PATH = lib.getExe' imagemagick "magick";

    RUSTFLAGS = with stdenv;
        lib.optional hostPlatform.isx86_64 "-Ctarget-cpu=x86-64-v3"
    ;

    doCheck = false;

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

