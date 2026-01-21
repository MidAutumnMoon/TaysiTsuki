{
    lib,
    stdenv,
    fetchFromGitHub,
    installShellFiles,

    tsuki,
    libjxl,
    imagemagick,
}:

tsuki.rust.buildRustPackage rec {

    pname = "inori";
    version = "0-unstable-2026-01-21";

    src = fetchFromGitHub {
        owner = "MidAutumnMoon";
        repo = "InOri";
        rev = "e24438aa9b40f16d4cfc704d4bb6bd2d89cc866e";
        hash = "sha256-zgKckmC72p/s3jdAf6NdQg0PEjamHCyicaKEMDfWXLk=";
    };

    cargoHash = "sha256-ZHxHPQBmAZc1AC476gGy+y3fuLMO9V0jMb6NEbWRxGs=";

    doCheck = false;

    outputs = [
        "out"
        "busnaguri"
        "lny"
    ];

    nativeBuildInputs = [
        installShellFiles
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

    postInstall =
        let
            canExe = with stdenv;
                buildPlatform.canExecute hostPlatform;
        in lib.optionalString canExe ''
            bin="$out/bin/i"
            installShellCompletion --cmd i \
                --bash <("$bin" gen-complete -s bash) \
                --fish <("$bin" gen-complete -s fish) \
                --zsh <("$bin" gen-complete -s zsh)
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
