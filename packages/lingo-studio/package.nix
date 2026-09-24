{
    lib,
    stdenv,
    fetchFromGitHub,
    fetchPnpmDeps,
    fetchurl,
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
    libevdev,
    libgbm,
    libx11,
    libxcb,
    libxcomposite,
    libxdamage,
    libxext,
    libxkbcommon,
    libxrandr,
    libxtst,
    libxfixes,
    wayland,
    nspr,
    nss,
    pango,
    systemd,
    vulkan-loader,
    libglvnd,
    commandLineArgs ? "",
}:

let
    electron = electron_44-bin.overrideAttrs (self: super: {
        # Locked nixpkgs' electron-bin postFixup ends with a patchelf pass
        # over `$out/libexec/electron/lib*GL*`, but electron 44 bundles no
        # ANGLE libs; stdenv's nullglob leaves that call without a single
        # filename and the build dies. Upstream gates the stanza on
        # `version < "44"` — splice it out here and re-append the
        # vulkan-loader replacement that followed it. Drop this override
        # when the flake lock moves past the fix.
        postFixup =
            lib.head (lib.split "# patch libANGLE" super.postFixup)
            + /*sh*/ ''
                # replace bundled vulkan-loader
                rm "$out/libexec/electron/libvulkan.so.1"
                ln -s -t "$out/libexec/electron" "${lib.getLib vulkan-loader}/lib/libvulkan.so.1"
            '';
    });
    pnpm = pnpm_12;

    # Upstream's electron-builder beforePack hook fetches prebuilt
    # GLIBC-portable better-sqlite3 addons from GitHub, pinned by sha256 in
    # scripts/linux-native/release.json. Seed that cache so the build stays
    # offline; the hook re-verifies both files against the same pins.
    sqliteRelease = "better-sqlite3-v12.11.1-electron-v44.2.0-r2";
    sqliteArtifacts = {
        x64 = {
            addon = fetchurl {
                url = "https://github.com/CherryHQ/cherry-studio-better-sqlite3/releases/download/${sqliteRelease}/better_sqlite3-v12.11.1-electron-v44.2.0-linux-x64.node";
                hash = "sha256-ISdVyO7ACYULGlCAOTeGTUZO1mnAweJQbLNUzAarFIc=";
            };
            manifest = fetchurl {
                url = "https://github.com/CherryHQ/cherry-studio-better-sqlite3/releases/download/${sqliteRelease}/better_sqlite3-v12.11.1-electron-v44.2.0-linux-x64.manifest.json";
                hash = "sha256-+RveiqNHsbmSSYzIlu6dLF42Y5RiKOu9BNbGnBK0Hoc=";
            };
        };
        arm64 = {
            addon = fetchurl {
                url = "https://github.com/CherryHQ/cherry-studio-better-sqlite3/releases/download/${sqliteRelease}/better_sqlite3-v12.11.1-electron-v44.2.0-linux-arm64.node";
                hash = "sha256-+/t5jUSVvgfmADyq/5qY5t5RCjG47cwpfBiXkf8ADxQ=";
            };
            manifest = fetchurl {
                url = "https://github.com/CherryHQ/cherry-studio-better-sqlite3/releases/download/${sqliteRelease}/better_sqlite3-v12.11.1-electron-v44.2.0-linux-arm64.manifest.json";
                hash = "sha256-9p8F9k16QZ8fkDG5rEdjPh2uUIIJzz/wWo4EXFm4hew=";
            };
        };
    };

    arch =
        with stdenv.hostPlatform;
        if isAarch64 then "arm64"
        else if isx86_64 then "x64"
        else throw "lingo-studio: unsupported platform";

    unpackedDir = "dist/linux${lib.optionalString stdenv.hostPlatform.isAarch64 "-arm64"}-unpacked";
in
stdenv.mkDerivation (drvSelf: {
    pname = "lingo-studio";
    version = "0-unstable-2026-09-24";

    src = fetchFromGitHub {
        owner = "MidAutumnMoon";
        repo = "lingo-studio";
        rev = "844cb4cb1cb7d26b5ec451f5f81f0d826d2a8dd6";
        hash = "sha256-iYIFNf0jHY509rCWIeHHrZdnYktdOWBh8lLMn0gLrNc=";
    };

    # Updates are delivered through this flake; neuter the in-app updater at
    # its single choke point (scheduled ticks and manual IPC checks both go
    # through performUpdateCheck).
    postPatch = ''
        substituteInPlace .npmrc \
            --replace-fail "engine-strict=true" ""
        substituteInPlace src/main/services/AppUpdaterService.ts \
            --replace-fail "void application.get('AnalyticsService').trackAppUpdate()" \
            "return { currentVersion: app.getVersion(), updateInfo: null }"
        # The executable's basename must not be "electron": electron's
        # app.isPackaged is derived from process.execPath, and the dev-mode
        # branch misresolves the extraResources paths (DbService fails to
        # find the provider registry).
        substituteInPlace electron-builder.yml \
            --replace-fail "executableName: CherryStudio" "executableName: lingo-studio"
    '';

    pnpmDeps = fetchPnpmDeps {
        inherit (drvSelf) pname version src;
        inherit pnpm;
        fetcherVersion = 4;
        hash = "sha256-R2RMCzHLvJ43LoeaG8D12H8euJHx5dQcQhEVHKOrhRA=";
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
        # stdenv.cc + the .node prebuilds' closure
        stdenv.cc.cc.lib
        alsa-lib
        dbus
        libevdev
        libx11
        libxtst
        libxfixes
        wayland
        # the copied electron runtime's DT_NEEDED closure (matches
        # nixpkgs' electron-bin electronLibPath)
        atk
        at-spi2-atk
        at-spi2-core
        cairo
        cups
        expat
        glib
        gtk3
        libgbm
        libxcb
        libxcomposite
        libxdamage
        libxext
        libxkbcommon
        libxrandr
        nspr
        nss
        pango
        systemd
    ];

    autoPatchelfIgnoreMissingDeps = [
        "libc.musl-*.so.*"
    ];

    strictDeps = true;

    appendRunpaths =
        map (p: "${lib.getLib p}/lib") [
            libglvnd
            vulkan-loader
        ];

    env.ELECTRON_SKIP_BINARY_DOWNLOAD = "1";

    buildPhase = /*sh*/ ''
        runHook preBuild

        # pnpmConfigHook installs with --ignore-scripts, so the root
        # postinstall (bundling the dsh-bridge runtime) never ran.
        pnpm --filter @cherrystudio/dsh-bridge build

        export CHERRY_EDITION=global
        node_modules/.bin/electron-vite build
        node_modules/.bin/electron-vite build --config electron.vite.entries.config.ts

        install -Dm644 ${sqliteArtifacts.${arch}.manifest} scripts/linux-native/prebuilt/${arch}/manifest.json
        install -Dm644 ${sqliteArtifacts.${arch}.addon} scripts/linux-native/prebuilt/${arch}/better_sqlite3.node

        # With install-scripts and electron-builder's rebuild both skipped,
        # better-sqlite3 has no build/Release output; afterPack requires the
        # packaged addon to exist before swapping in the pinned artifact, so
        # seed it with the same verified bytes.
        install -Dm644 ${sqliteArtifacts.${arch}.addon} node_modules/better-sqlite3/build/Release/better_sqlite3.node

        cp -r "${electron.dist}" $HOME/.electron-dist
        chmod -R u+w $HOME/.electron-dist

        # Native modules ship as upstream prebuilds and afterPack swaps in the
        # pinned better-sqlite3, so skip electron-builder's rebuild entirely.
        node_modules/.bin/electron-builder --dir \
            --config=electron-builder.yml \
            --config.mac.identity=null \
            --config.npmRebuild=false \
            --config.electronDist="$HOME/.electron-dist" \
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

        # Install electron-builder's unpacked output wholesale: it contains
        # the renamed electron binary, its runtime files, and our app in
        # resources/app.asar. Loading the app from its own resources dir is
        # what flips app.isPackaged and points every extraResources path
        # (registry, migrations) at the shipped files.
        mkdir -p $out/opt
        cp -r ${unpackedDir} $out/opt/lingo-studio
        install -Dm644 build/icon.png $out/share/icons/lingo-studio.png
        makeWrapper $out/opt/lingo-studio/lingo-studio $out/bin/lingo-studio \
            --inherit-argv0 \
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
