{
    lib,
    stdenvNoCC,
    stdenv,
    fetchurl,
    kmod,
    zstd,
}:

{
    pname,
    version,
    packageVersion,
    architecture,
    modDirVersion,
    kernel,
    headers,
    generatedConfig,
    configHash,
    isLTS ? false,
    isZen ? false,

    # NixOS always supplies these through boot.kernelPackages' apply hook.
    kernelPatches ? [ ],
    features ? { },
    randstructSeed ? "",
}:

assert lib.assertMsg (kernelPatches == [ ])
    "${pname}: patches cannot be applied to a prebuilt kernel";
assert lib.assertMsg (randstructSeed == "")
    "${pname}: randstructSeed cannot be applied to a prebuilt kernel";

let

    fetchPackage = source: fetchurl {
        inherit (source) url hash;
    };

    kernelArchive = fetchPackage kernel;
    headersArchive = fetchPackage headers;

    normalizedGeneratedConfig =
        generatedConfig
        |> lib.mapAttrsToList (name: value: "${name}=${value}")
        |> lib.sort (left: right: left < right)
        |> lib.concatStringsSep "\n"
        |> (text: text + "\n");

    # A separate derivation gives passthru.configfile a real store dependency.
    # It also proves that release.json, config.json, and the headers archive
    # all describe the same kernel before NixOS consumes the config.
    kernelConfigFile = stdenvNoCC.mkDerivation {
        name = "${pname}-${packageVersion}-config";
        src = headersArchive;

        strictDeps = true;
        dontUnpack = true;

        nativeBuildInputs = [ zstd ];

        configAttrNormalized = normalizedGeneratedConfig;
        passAsFile = [ "configAttrNormalized" ];

        installPhase = /* bash */ ''
            root="$PWD/root"
            mkdir "$root"
            tar --zstd -xf "$src" -C "$root" \
                --wildcards \
                '.PKGINFO' \
                'usr/lib/modules/*/build/.config'

            actualPackageName="$(sed -n 's/^pkgname = //p' "$root/.PKGINFO")"
            actualPackageVersion="$(sed -n 's/^pkgver = //p' "$root/.PKGINFO")"
            if [ "$actualPackageName" != "${headers.packageName}" ] \
                || [ "$actualPackageVersion" != "${packageVersion}" ]; then
                echo "error: headers package identity is '$actualPackageName-$actualPackageVersion'; expected '${headers.packageName}-${packageVersion}'" >&2
                exit 1
            fi

            moduleDirs=( "$root"/usr/lib/modules/* )
            actualModuleDir="''${moduleDirs[0]##*/}"
            if [ "''${#moduleDirs[@]}" -ne 1 ] \
                || [ "$actualModuleDir" != "${modDirVersion}" ]; then
                echo "error: headers module directory is '$actualModuleDir'; expected '${modDirVersion}'" >&2
                exit 1
            fi

            headersBuild="$root/usr/lib/modules/${modDirVersion}/build"

            actualConfigHash="$(sha256sum "$headersBuild/.config" | cut -d' ' -f1)"
            if [ "$actualConfigHash" != "${configHash}" ]; then
                echo "error: headers config sha256 is '$actualConfigHash'; expected '${configHash}'" >&2
                exit 1
            fi

            if ! sed -n '/^CONFIG_[A-Za-z0-9_]*=/p' "$headersBuild/.config" \
                | LC_ALL=C sort \
                | diff -u "$configAttrNormalizedPath" -; then
                echo "error: packages/cachyos/config.json does not match the headers .config" >&2
                echo "       regenerate it with: nix run .#tsuki.ci-driver -- cachyos gen-config CONFIG -o packages/cachyos/config.json" >&2
                exit 1
            fi

            install -Dm644 "$headersBuild/.config" "$out"
        '';
    };

    optionName = name: "CONFIG_${name}";

    config = generatedConfig // rec {
        isSet = name:
            lib.hasAttr (optionName name) generatedConfig;

        getValue = name:
            if isSet name then
                lib.getAttr (optionName name) generatedConfig
            else
                null;

        isYes = name: getValue name == "y";
        isNo = name: getValue name == "n";
        isModule = name: getValue name == "m";
        isEnabled = name: isYes name || isModule name;
        isDisabled = name: !(isSet name) || isNo name;
    };

    # NixOS uses this metadata for behavior that must be known at evaluation
    # time. Derive the defaults from the imported config; callers may add or
    # override feature facts through boot.kernel.features.
    kernelFeatures = {
        efiBootStub = config.isYes "EFI_STUB";
        ia32Emulation = config.isYes "IA32_EMULATION";
        netfilterRPFilter = config.isEnabled "IP_NF_MATCH_RPFILTER";
    } // features;

    isModular = config.isYes "MODULES";

    baseVersion = lib.head (lib.splitString "-rc" version);

in

assert lib.assertMsg isModular
    "${pname}: importing a kernel without CONFIG_MODULES is unsupported";

stdenvNoCC.mkDerivation {
    inherit pname version;

    outputs = [
        "out"
        "modules"
    ];

    src = kernelArchive;

    strictDeps = true;
    dontUnpack = true;

    nativeBuildInputs = [
        kmod
        zstd
    ];

    # The upstream image and modules must remain byte-identical.
    dontStrip = true;
    dontPatchELF = true;
    noAuditTmpdir = true;

    installPhase = /* bash */ ''
        root="$PWD/root"
        mkdir "$root"
        tar --zstd -xf "$src" -C "$root"

        actualPackageName="$(sed -n 's/^pkgname = //p' "$root/.PKGINFO")"
        actualPackageVersion="$(sed -n 's/^pkgver = //p' "$root/.PKGINFO")"
        if [ "$actualPackageName" != "${kernel.packageName}" ] \
            || [ "$actualPackageVersion" != "${packageVersion}" ]; then
            echo "error: kernel package identity is '$actualPackageName-$actualPackageVersion'; expected '${kernel.packageName}-${packageVersion}'" >&2
            exit 1
        fi

        moduleDirs=( "$root"/usr/lib/modules/* )
        actualModuleDir="''${moduleDirs[0]##*/}"
        if [ "''${#moduleDirs[@]}" -ne 1 ] \
            || [ "$actualModuleDir" != "${modDirVersion}" ]; then
            echo "error: kernel module directory is '$actualModuleDir'; expected '${modDirVersion}'" >&2
            exit 1
        fi

        moduleRoot="$root/usr/lib/modules/${modDirVersion}"
        for required in \
            vmlinuz \
            modules.builtin \
            modules.builtin.modinfo \
            modules.order
        do
            if [ ! -f "$moduleRoot/$required" ]; then
                echo "error: '$required' is missing from the kernel package" >&2
                exit 1
            fi
        done

        mkdir -p "$out"
        cp -a "$moduleRoot/vmlinuz" "$out/bzImage"

        mkdir -p "$modules/lib/modules"
        cp -a "$moduleRoot" "$modules/lib/modules/${modDirVersion}"
        rm -f \
            "$modules/lib/modules/${modDirVersion}/vmlinuz" \
            "$modules/lib/modules/${modDirVersion}/pkgbase"

        # CachyOS suppresses depmod while creating the Arch package.
        depmod -b "$modules" "${modDirVersion}"
    '';

    passthru = {
        inherit
            version
            packageVersion
            architecture
            modDirVersion
            config
            isModular
            kernelPatches
            stdenv
            baseVersion
            isLTS
            isZen
        ;

        features = kernelFeatures;

        configfile = kernelConfigFile;
        target = "bzImage";
        buildDTBs = false;

        kernelOlder = lib.versionOlder baseVersion;
        kernelAtLeast = lib.versionAtLeast baseVersion;
    };

    meta = {
        description = "Prebuilt CachyOS Linux kernel (${kernel.packageName} ${packageVersion}, ${architecture})";
        homepage = "https://cachyos.org/";
        license = lib.licenses.gpl2Only;
        platforms = [ "x86_64-linux" ];
        sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    };
}
