{
    lib,
    stdenv,
    fetchFromGitHub,
    fetchPnpmDeps,
    makeDesktopItem,
    makeWrapper,
    copyDesktopItems,
    writableTmpDirAsHomeHook,
    autoPatchelfHook,
    electron_44-bin,
    nodejs-slim,
    pnpm_12,
    pnpmConfigHook,
    alsa-lib,
    atk,
    at-spi2-atk,
    at-spi2-core,
    cairo,
    cups,
    dbus,
    expat,
    glib,
    gtk3,
    libgbm,
    libx11,
    libxcb,
    libxcomposite,
    libxdamage,
    libxext,
    libxkbcommon,
    libxrandr,
    libxfixes,
    nspr,
    nss,
    pango,
    systemd,
    vulkan-loader,
    libglvnd,
    commandLineArgs ? "",
}:

let
    electron = electron_44-bin;
    pnpm = pnpm_12;

    unpackedDir = "dist/linux${lib.optionalString stdenv.hostPlatform.isAarch64 "-arm64"}-unpacked";
in
stdenv.mkDerivation (drvSelf: {
    pname = "lingo-studio";
    version = "0-unstable-2026-10-08";

    src = fetchFromGitHub {
        owner = "MidAutumnMoon";
        repo = "lingo-studio";
        rev = "50afbb614d37d775983b8a53a7276815ab24d993";
        hash = "sha256-6iEV1cXVDdd/ED9jAhoTv1AiXY6Z9l5Vovl3vK0C8V0=";
    };

    postPatch = ''
        # executableName decides the unpacked binary's name; installPhase
        # and the desktop entry expect "lingo-studio".
        substituteInPlace electron-builder.yml \
            --replace-fail "executableName: CherryStudio" "executableName: lingo-studio"
    '';

    pnpmDeps = fetchPnpmDeps {
        inherit (drvSelf) pname version src;
        inherit pnpm;
        fetcherVersion = 4;
        hash = "sha256-iw3hl6pFiEUUyAFrpcDL4dA6MDk9il+cRcYj1aNMfbk=";
    };

    nativeBuildInputs = [
        nodejs-slim
        pnpm
        pnpmConfigHook
        makeWrapper
        writableTmpDirAsHomeHook
        copyDesktopItems
        autoPatchelfHook
    ];

    buildInputs = [
        # libstdc++ for the .node prebuilds (koffi, node-pty, sharp,
        # better-sqlite3); the rest is the electron runtime's DT_NEEDED
        # closure, as in nixpkgs electron-bin's electronLibPath.
        stdenv.cc.cc.lib
        alsa-lib
        atk
        at-spi2-atk
        at-spi2-core
        cairo
        cups
        dbus
        expat
        glib
        gtk3
        libgbm
        libx11
        libxcb
        libxcomposite
        libxdamage
        libxext
        libxfixes
        libxkbcommon
        libxrandr
        nspr
        nss
        pango
        systemd
    ];

    # koffi bundles gnu and musl koffi.node variants and picks per-libc at
    # runtime; the musl copy can never resolve libc.musl on NixOS.
    autoPatchelfIgnoreMissingDeps = [
        "libc.musl-*.so.*"
    ];

    strictDeps = true;

    appendRunpaths =
        map (p: "${lib.getLib p}/lib") [
            libglvnd
            vulkan-loader
        ];

    env = {
        NODE_ENV = "production";
        ELECTRON_SKIP_BINARY_DOWNLOAD = "1";
    };

    buildPhase = /*sh*/ ''
        runHook preBuild

        # pnpmConfigHook installs with --ignore-scripts, so the root
        # postinstall (bundling the dsh-bridge runtime) never ran.
        pnpm --filter @cherrystudio/dsh-bridge build

        node_modules/.bin/electron-vite build

        # Native modules ship N-API prebuilds that beforePack filters to the
        # target platform-arch, so no rebuild is needed. electronDist is
        # copied, not mutated, so the store path works as-is.
        node_modules/.bin/electron-builder --dir \
            --config=electron-builder.yml \
            --config.npmRebuild=false \
            --config.electronDist="${electron.dist}" \
            --config.electronVersion=${electron.version}

        runHook postBuild
    '';

    desktopItems = [
        (makeDesktopItem {
            name = "lingo-studio";
            desktopName = "Lingo Studio";
            comment = "A powerful AI assistant for producer.";
            exec = "lingo-studio --no-sandbox %U";
            terminal = false;
            icon = "lingo-studio";
            startupWMClass = "CherryStudio";
            categories = [ "Utility" ];
            mimeTypes = [ "x-scheme-handler/cherrystudio" ];
        })
    ];

    installPhase = /*sh*/ ''
        runHook preInstall

        # The unpacked dir already holds the electron runtime, app.asar,
        # unpacked natives and extraResources; copy it wholesale.
        mkdir -p $out/opt
        cp -r ${unpackedDir} $out/opt/lingo-studio
        install -Dm644 build/icon.png $out/share/icons/lingo-studio.png
        makeWrapper $out/opt/lingo-studio/lingo-studio $out/bin/lingo-studio \
            --inherit-argv0 \
            --set "NODE_ENV" "production" \
            --add-flags "--no-sandbox" \
            --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations --enable-wayland-ime=true --wayland-text-input-version=3}}" \
            --add-flags ${lib.escapeShellArg commandLineArgs}

        runHook postInstall
    '';

    doCheck = false;

    meta = {
        description = "Personal Cherry Studio build, a desktop client for multiple LLM providers";
        homepage = "https://github.com/MidAutumnMoon/lingo-studio";
        mainProgram = "lingo-studio";
        platforms = lib.platforms.linux;
        license = lib.licenses.agpl3Only;
    };
})
