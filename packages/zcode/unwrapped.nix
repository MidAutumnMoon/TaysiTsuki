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
    version = "3.14.5";

    src = fetchurl {
        url = "https://cdn-zcode.z.ai/zcode/electron/releases/${drvSelf.version}/linux-x64/ZCode-${drvSelf.version}-linux-x64.deb";
        hash = "sha256-rBqNy6Zb2FAQ8Uih5cCEuh1Bspy6Fp+qJihAa8L8W88=";
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
        runHook preUnpack
        ${lib.getExe' bintools "ar"} x $src
        tar xf data.tar.xz
        runHook postUnpack
    '';

    installPhase = /* sh */ ''
        runHook preInstall
        mkdir -p $out/lib $out/share
        cp -a opt/ZCode $out/lib/ZCode
        cp -a usr/share/icons $out/share/icons
        chmod +x $out/lib/ZCode/zcode $out/lib/ZCode/chrome_crashpad_handler
        runHook postInstall
    '';
})
