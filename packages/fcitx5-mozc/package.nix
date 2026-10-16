# Self-contained mozc for fcitx5: the addon, mozc_server and mozc_tool in
# one output, built from the fcitx/mozc fork (google/mozc plus the fcitx5
# frontend) with no separate `mozc` package. The fork takes google/master
# through frequent bot merges but publishes no usable tags, so the pin is a
# commit on the `fcitx` branch.
#
# mozc 3.x needs Bazel 9 and MODULE.bazel (bzlmod), which buildBazelPackage
# cannot build. Instead a recursive FOD runs `bazel vendor` and the main
# derivation builds offline from the vendor dir, following nixpkgs
# PR #531687.
#
# Bumping is manual because the vendor FOD hash defeats nix-update:
#   1. git ls-remote https://github.com/fcitx/mozc refs/heads/fcitx
#   2. update rev, version (0-unstable-<commit date>), and set both hashes
#      to sha256-AAA...
#   3. nix build .#fcitx5-mozc, fixing first the src hash, then the vendor
#      hash, from the "got: sha256-..." errors
# The vendor FOD takes its proxy from the ambient environment like fetchurl
# (impureEnvVars), so the nix daemon must see the proxy vars. Behind mihomo
# that means a one-time `systemctl edit nix-daemon` with
# Environment="http_proxy=...". The vars change how bytes are fetched,
# never the output hash.
{
    lib,
    stdenv,
    fetchFromGitHub,
    bazel_9,
    fcitx5,
    gettext,
    libglvnd,
    libxcrypt-legacy,
    pkg-config,
    python3,
    qt6,
    writableTmpDirAsHomeHook,
    xdg-utils,
}:

let

    bazel = bazel_9;

    # Internal mozc version at this rev: 3.35.6354.2 (stable_channel).
    pname = "fcitx5-mozc";
    version = "0-unstable-2026-10-16";
    rev = "a74b67127d710da4dc6fdbbd17320d04741174de";

    src = fetchFromGitHub {
        owner = "fcitx";
        repo = "mozc";
        inherit rev;
        hash = "sha256-ITFhc3IetbFWThMoidIDvMWl2gCxiWVyVwxbLCQBSDI=";
    };

    # The vendor FOD reuses this list without gettext, which only the
    # install scripts need (msgfmt).
    commonNativeBuildInputs = [
        bazel
        pkg-config
        python3
        writableTmpDirAsHomeHook
    ];

    nativeBuildInputs = commonNativeBuildInputs ++ [
        gettext
    ];

    buildInputs = [
        fcitx5
        libglvnd
        libxcrypt-legacy
        qt6.qtbase
    ];

    includePath = lib.makeIncludePath buildInputs;
    libraryPath = lib.makeLibraryPath buildInputs;

    bazelArgs = [
        "--config=oss_linux"
        "--config=stable_channel"
        "--config=release_build"
        # Build protoc from source instead of downloading a host binary.
        "--@com_google_protobuf//bazel/flags:prefer_prebuilt_protoc=false"
        "--action_env=C_INCLUDE_PATH=${includePath}"
        "--action_env=CPLUS_INCLUDE_PATH=${includePath}"
        "--action_env=LIBRARY_PATH=${libraryPath}"
        "server:mozc_server"
        "gui/tool:mozc_tool"
        "unix/fcitx5:fcitx5-mozc.so"
    ];

    # Bind rules_python to our python3 instead of a downloaded standalone one.
    bazelPythonConfig = /*starlark*/ ''
        local_runtime_repo = use_repo_rule(
            "@rules_python//python/local_toolchains:repos.bzl",
            "local_runtime_repo",
        )
        local_runtime_toolchains_repo = use_repo_rule(
            "@rules_python//python/local_toolchains:repos.bzl",
            "local_runtime_toolchains_repo",
        )
        local_runtime_repo(
            name = "local_python3",
            interpreter_path = "python3",
            on_failure = "fail",
        )
        local_runtime_toolchains_repo(
            name = "local_toolchains",
            runtimes = ["local_python3"],
        )
        register_toolchains("@local_toolchains//:all")
    '';

    # Scrub host-local state so the fixed output does not depend on the
    # building machine.
    vendorDeps = stdenv.mkDerivation (
        lib.fetchers.normalizeHash { } {
            pname = "${pname}-vendor";
            inherit
                src
                version
                ;

            nativeBuildInputs = commonNativeBuildInputs;
            inherit buildInputs;

            outputHashMode = "recursive";
            hash = "sha256-jQNmOJwPcsg3RNNHKWpI4CTZ3B+TmaaWpwcCkcdU79Q=";

            strictDeps = true;
            __structuredAttrs = true;

            impureEnvVars = lib.fetchers.proxyImpureEnvVars;

            buildPhase = /*sh*/ ''
                runHook preBuild

                cd src

                cat >> MODULE.bazel << EOF
                ${bazelPythonConfig}
                EOF

                bazel vendor --lockfile_mode=update --vendor_dir="$out/vendor_dir" ${lib.escapeShellArgs bazelArgs}
                cp MODULE.bazel.lock "$out"

                find "$out" -type l -lname '/*' -delete
                find "$out" -xtype l -delete
                find "$out/vendor_dir" -maxdepth 1 -type f -name '*.marker' -delete
                rm -rf \
                    "$out"/vendor_dir/*local_python3* \
                    "$out"/vendor_dir/*go_sdk+go_toolchains*

                runHook postBuild
            '';

            dontInstall = true;
            dontFixup = true;
            dontWrapQtApps = true;
        }
    );

    setupBazelVendor = /*sh*/ ''
        cat >> MODULE.bazel << EOF
        ${bazelPythonConfig}
        EOF

        cp -r "${vendorDeps}"/* .
        chmod -R u+w vendor_dir
        # The local runtime otherwise generates scripts with /usr/bin/env shebangs.
        substituteInPlace vendor_dir/rules_python*/python/private/local_runtime_repo_setup.bzl \
            --replace-fail 'interpreter_path = interpreter_path,' \
                'interpreter_path = interpreter_path, stub_shebang = "#!${lib.getExe python3}",'
        patchShebangs --build vendor_dir
        find vendor_dir -mindepth 1 -maxdepth 1 -type d -printf 'pin("@@%P")\n' > vendor_dir/VENDOR.bazel
    '';

in
stdenv.mkDerivation {
    inherit
        pname
        version
        src
        nativeBuildInputs
        buildInputs
        ;

    strictDeps = true;
    __structuredAttrs = true;

    # mozc_tool sits in lib/mozc, outside the wrap hook's search paths, and
    # qtbase's baked-in plugin paths make a wrapper unnecessary.
    dontWrapQtApps = true;

    postPatch = /*sh*/ ''
        patchShebangs --build scripts

        cd src

        ${setupBazelVendor}

        # xdg-open needs rewriting before the generic /usr pass, which would
        # point it into $out.
        substituteInPlace config.bzl \
            --replace-fail "/usr/bin/xdg-open" "${xdg-utils}/bin/xdg-open" \
            --replace-fail "/usr" "$out"
    '';

    buildPhase = /*sh*/ ''
        runHook preBuild

        bazel build --lockfile_mode=error --vendor_dir=vendor_dir ${lib.escapeShellArgs bazelArgs}

        runHook postBuild
    '';

    installPhase = /*sh*/ ''
        runHook preInstall

        PREFIX="$out" ../scripts/install_server_bazel
        PREFIX="$out" ../scripts/install_fcitx5_bazel

        # The about dialog reads credits from MOZC_DOCUMENT_DIR, which the
        # config.bzl rewrite points at $out/lib/mozc/documents.
        # install_server_bazel installs the html under share/doc instead.
        install -Dm644 data/installer/credits_en.html "$out/lib/mozc/documents/credits_en.html"

        install -Dm444 ../LICENSE "$out/share/licenses/${pname}/LICENSE"

        runHook postInstall
    '';

    passthru = {
        inherit vendorDeps;
    };

    meta = {
        description = "Mozc Japanese IME for fcitx5 — addon, server and tools from the fcitx fork";
        homepage = "https://github.com/fcitx/mozc";
        license = with lib.licenses; [
            asl20 # abseil-cpp
            bsd3 # mozc, breakpad, gtest, gyp, japanese-usage-dictionary, protobuf
            mit # wil
            naist-2003 # IPAdic
            publicDomain # src/data/test/stress_test, Okinawa dictionary
            unicode-30 # src/data/unicode, breakpad
        ];
        platforms = lib.platforms.linux;
    };
}
