{
    lib,
    stdenvNoCC,
    buildNpmPackage,
    fetchFromGitHub,
    makeBinaryWrapper,
    jq,
    playwright-driver,
}:

let

    # Raw CLI from npm. Browsers are supplied separately by the wrapper.
    #   - `PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1`: skip the postinstall fetch
    #     into the build sandbox; nixpkgs' browsers are wired in at runtime.
    unwrapped = buildNpmPackage rec {
        pname = "playwright-cli-unwrapped";
        version = "0.1.19";

        src = fetchFromGitHub {
            owner = "microsoft";
            repo = "playwright-cli";
            tag = "v${version}";
            hash = "sha256-pbv51ybubbjoIpKg0k7lfXfZ9Z+qdZI2lRhQeI+/mFA=";
        };

        npmDepsHash = "sha256-aY3i+sc2p8iQAEpfs+j/ifeBVmMpDDmwctEqOIDmCqI=";

        dontNpmBuild = true;

        env.PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD = "1";

        meta = {
            description = "Playwright CLI — token-efficient browser automation for coding agents";
            homepage = "https://github.com/microsoft/playwright-cli";
            license = lib.licenses.asl20;
            mainProgram = "playwright-cli";
        };
    };

    # Only chromium is wired into the wrapper (PLAYWRIGHT_MCP_BROWSER=chromium),
    # so source a closure-minimal browser set: no firefox/webkit/headless-shell.
    #   - `selectBrowsers` is nixpkgs playwright-driver's makeOverridable
    #     linkFarm builder; its closure holds only the selected components.
    #   - ffmpeg kept (small) so playwright-cli's video features still work.
    chromiumBrowsers = playwright-driver.selectBrowsers {
        withFirefox = false;
        withWebkit = false;
        withChromiumHeadlessShell = false;
    };

    # Alias nixpkgs' browsers under the revisions playwright-cli expects.
    #
    # Why: Playwright resolves a browser by directory name `<name>-<rev>`
    # inside $PLAYWRIGHT_BROWSERS_PATH. The `<rev>` is pinned to the bundled
    # Playwright version, which can differ from nixpkgs' playwright-driver.
    # A mismatch = directory not found = silent fallback to internet download.
    #
    # Fix: read expected revs from the bundled browsers.json and symlink them
    # to whatever nixpkgs ships.
    #
    # Safety:
    #   - Browsers are driven over CDP, tolerant of minor version drift.
    #   - Diverging revisions are surfaced as a build-time warning.
    #   - Breaks if nixpkgs lags the bundled Playwright by a major version.
    browsers = stdenvNoCC.mkDerivation {
        pname = "playwright-cli-browsers";
        inherit (unwrapped) version;

        nativeBuildInputs = [ jq ];

        dontUnpack = true;

        installPhase = ''
            runHook preInstall

            browsersJson="$(
                find "${unwrapped}" -type f \
                    -path '*playwright-core*' -name browsers.json \
                | head -n1
            )"

            if [ -z "$browsersJson" ]; then
                echo "playwright-cli-browsers: could not locate browsers.json in the package" >&2
                exit 1
            fi

            mkdir -p "$out"

            srcBrowsers="${chromiumBrowsers}"
            haveChromium=false

            # Process substitution (not a pipe) keeps the loop in this shell so
            # haveChromium survives. @tsv reads name+revision in one jq pass.
            while IFS=$'\t' read -r name wantRev; do
                # Playwright mangles '-' into '_' for the on-disk dir name.
                norm="''${name//-/_}"

                # Match the source dir for this browser, ignoring its revision.
                actual="$(
                    set -- "$srcBrowsers"/"$norm"-*
                    if [ -e "$1" ]; then echo "$1"; fi
                )"

                if [ -z "$actual" ]; then
                    # Not in the chromium-only source set (firefox, webkit,
                    # headless-shell, tip-of-tree, beta, winldd, android).
                    continue
                fi

                # Rev is the suffix of the basename, not the whole store path.
                base="''${actual##*/}"
                gotRev="''${base##*-}"

                if [ "$wantRev" != "$gotRev" ]; then
                    echo "warning: playwright-cli-browsers: '$name' wanted revision $wantRev," \
                         "source provides $gotRev — aliasing anyway" >&2
                fi

                ln -s "$actual" "$out/$norm-$wantRev"
                [ "$norm" = chromium ] && haveChromium=true
            done < <(jq -r '.browsers[] | [.name, .revision] | @tsv' "$browsersJson")

            # chromium is the default browser (PLAYWRIGHT_MCP_BROWSER=chromium
            # in the wrapper). If it didn't alias, launches would silently fall
            # back to downloading — fail loud instead.
            if [ "$haveChromium" != true ]; then
                echo "error: playwright-cli-browsers: chromium was not aliased;" \
                     "source layout at '$srcBrowsers' may have changed" >&2
                exit 1
            fi

            runHook postInstall
        '';
    };

in
stdenvNoCC.mkDerivation {
    pname = "playwright-cli";
    inherit (unwrapped) version;

    # Force the bundled chromium over system Google Chrome.
    #
    # playwright-cli defaults to `channel: "chrome"` (system Google Chrome at
    # /opt/google/chrome/chrome), which bypasses $PLAYWRIGHT_BROWSERS_PATH and
    # fails on NixOS. `PLAYWRIGHT_MCP_BROWSER=chromium` resolves to the
    # "chrome-for-testing" chromium alias, which reads from BROWSERS_PATH.
    #
    # Precedence (low → high): default < env < `--browser` flag.
    # `--set-default` keeps it overridable by both.
    nativeBuildInputs = [ makeBinaryWrapper ];

    dontUnpack = true;

    installPhase = ''
        runHook preInstall
        mkdir -p "$out/bin"
        makeBinaryWrapper "${lib.getExe unwrapped}" "$out/bin/playwright-cli" \
            --set-default PLAYWRIGHT_BROWSERS_PATH "${browsers}" \
            --set-default PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS 1 \
            --set-default PLAYWRIGHT_MCP_BROWSER chromium
        runHook postInstall
    '';

    passthru = {
        inherit unwrapped browsers;
        driver = playwright-driver;
    };

    meta = unwrapped.meta;
}
