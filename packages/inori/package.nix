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
    version = "0-unstable-2025-06-17";

    src = fetchFromGitHub {
        owner = "MidAutumnMoon";
        repo = "InOri";
        rev = "e6d62fe40b775d0ce2d1c4f900058752a55cb237";
        hash = "sha256-/L7ujqt2F8UuizkeEHBhBU5KdUG0sdOzkUgVYtP7F/4=";
    };

    cargoHash = "sha256-kVMGlyR3+oVdy9Xp7UOLirWNLyg2T+yBFa62Zj5i07I=";
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

