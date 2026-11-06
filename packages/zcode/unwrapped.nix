{
    lib,
    stdenvNoCC,
    bintools,
    gnutar,
    xz,
    fetchurl,
}:

stdenvNoCC.mkDerivation (drvSelf: {
    pname = "zcode-unwrapped";
    version = "3.17.2";

    src = fetchurl {
        url = "https://cdn-zcode.z.ai/zcode/electron/releases/${drvSelf.version}/linux-x64/ZCode-${drvSelf.version}-linux-x64.deb";
        hash = "sha256-hux7KnlcRq5W5zE1BDAKM3wzxoJnwo+WoDcmpPWv9XU=";
    };

    nativeBuildInputs = [
        bintools
        gnutar
        xz
    ];

    # Untouched: the FHS env provides the system libs, and the bundled
    # ones resolve via $ORIGIN.
    dontPatchELF = true;
    dontStrip = true;

    sourceRoot = ".";
    unpackPhase = /* sh */ ''
        ${lib.getExe' bintools "ar"} x $src
        tar xf data.tar.xz
    '';

    installPhase = /* sh */ ''
        mkdir -p $out/lib $out/share
        cp -a opt/ZCode $out/lib/ZCode
        cp -a usr/share/icons $out/share/icons
        chmod +x $out/lib/ZCode/zcode $out/lib/ZCode/chrome_crashpad_handler
    '';
})
