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

tsuki.rust.buildRustPackage {

    pname = "inori";
    version = "0-unstable-2025-06-18";

    src = fetchFromGitHub {
        owner = "MidAutumnMoon";
        repo = "InOri";
        rev = "1fcedd4038b643023bca2475a9421635501a8998";
        hash = "sha256-EGWhN4RZMUQXc3k1iwEa/9OhRTqDz3q03slApdeou4w=";
    };

    cargoHash = "sha256-iLUS7ohKebuePKvSN5vXtp29t99lz0lDlWOPCSPgPSg=";
    useFetchCargoVendor = true;

    nativeCheckInputs = [
        writableTmpDirAsHomeHook
    ];

    preCheck = ''
        export XDG_RUNTIME_DIR="$HOME/rt"
        export XDG_DATA_HOME="$HOME/data"
        export XDG_CONFIG_HOME="$HOME/cfg"
        export XDG_CACHE_HOME="$HOME/cache"
        export XDG_STATE_HOME="$HOME/st"
    '';

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

