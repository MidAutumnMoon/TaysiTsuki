# Upstream zcode .deb, unmodified, in an FHS sandbox from this flake's
# nixpkgs: everything but the payload shares the host's ABI generation.
{
    lib,
    pkgs,
    tsuki,
    buildFHSEnv,
    callPackage,
    makeDesktopItem,
    runCommand,
    bintools,
    file,
    findutils,
    glibc,
}:

let

    unwrapped = callPackage ./unwrapped.nix {};
    targetPkgs = import ./target.nix;

    # Runs after the FHS profile's exports, so the unsets stick — zcode's
    # terminals inherit whatever stays. nixpkgs composes ${profile} last,
    # so the agentcept prepend lands ahead of the FHS base PATH export,
    # with the real find/grep still reachable behind it for agentcept's
    # pass-through.
    hygieneProfile = /* sh */ ''
        unset NIX_CFLAGS_COMPILE NIX_CFLAGS_LINK NIX_LDFLAGS \
            PKG_CONFIG_PATH ACLOCAL_PATH GST_PLUGIN_SYSTEM_PATH_1_0
        export PATH="${tsuki.inori.agentcept}/bin:$PATH"
    '';

    # runScript must stay one line — the FHS init execs it verbatim.
    waylandFlags = ''''${NIXOS_OZONE_WL:+''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations --enable-wayland-ime=true}}'';

    desktopItem = makeDesktopItem {
        name = "zcode";
        desktopName = "ZCode";
        genericName = "Agentic Development Environment";
        comment = "ZCode Desktop App";
        exec = "zcode %U";
        icon = "zcode";
        categories = [ "Development" ];
        startupWMClass = "ZCode";
        mimeTypes = [ "x-scheme-handler/zcode" ];
    };

    # FHS mode links nothing at build time; without this gate a new
    # upstream dependency would surface as a launch crash.
    libSearchPath =
        let
            fhsLibs = lib.makeLibraryPath (targetPkgs pkgs);
        in
        "${fhsLibs}:${lib.getLib pkgs.gcc.cc.lib}/lib:${lib.getLib glibc}/lib";

    depsCheck = runCommand "zcode-deps-check"
        {
            nativeBuildInputs = [
                bintools
                file
                findutils
            ];
        }
        /* sh */ ''
            status=0
            payloadDir=${unwrapped}/lib/ZCode
            while IFS= read -r -d ''' elf; do
                for soname in $(
                    ${lib.getExe' bintools "readelf"} -d "$elf" |
                    sed -n 's/.*(NEEDED).*\[\(.*\)\]$/\1/p'
                ); do
                    found=
                    IFS=: read -ra dirs <<< "${libSearchPath}"
                    for d in "''${dirs[@]}"; do
                        if [ -e "$d/$soname" ]; then
                            found=1
                            break
                        fi
                    done
                    # Payload RPATHs reach into subdirectories.
                    if [ -z "$found" ] && [ -n "$(
                        ${lib.getExe findutils} "$payloadDir" -name "$soname" -print -quit
                    )" ]; then
                        found=1
                    fi
                    if [ -z "$found" ]; then
                        echo "unresolved: $soname needed by $elf" >&2
                        status=1
                    fi
                done
            done < <(
                ${lib.getExe findutils} "$payloadDir" -type f -print0 |
                while IFS= read -r -d ''' f; do
                    # Skip the deb's foreign-arch addon blobs.
                    if [[ $(${lib.getExe file} -b "$f") == ELF*x86-64* ]]; then
                        printf '%s\0' "$f"
                    fi
                done
            )
            if [ "$status" -ne 0 ]; then
                exit 1
            fi
            touch $out
        '';

in
buildFHSEnv {
    pname = "zcode";
    version = unwrapped.version;

    inherit targetPkgs;

    # Sessions must outlive the launching terminal.
    dieWithParent = false;

    profile = hygieneProfile;
    runScript = "${unwrapped}/lib/ZCode/zcode ${waylandFlags}";

    extraInstallCommands = /* sh */ ''
        mkdir -p $out/share
        ln -s ${unwrapped}/share/icons $out/share/icons
        # Unthemed fallback icon, for icon loaders that skip hicolor.
        mkdir -p $out/share/pixmaps
        ln -s ../icons/hicolor/512x512/apps/zcode.png $out/share/pixmaps/zcode.png
        install -Dm444 ${desktopItem}/share/applications/zcode.desktop \
            $out/share/applications/zcode.desktop
    '';

    passthru = {
        inherit unwrapped;
        tests = {
            deps = depsCheck;
            ldd = callPackage ./lddcheck.nix {
                inherit unwrapped targetPkgs;
            };
        };
    };

    meta.platforms = [ "x86_64-linux" ];
}
