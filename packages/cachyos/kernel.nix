# Shout out to: https://github.com/xddxdd/nix-cachyos-kernel
{
    lib,
    runCommand,
    stdenv,
    rsync,
    perl,
    buildLinux,
    linuxKernel,

    # The base kernel to grab version and src from.
    baseKernel,
    kernelPatches,
    kernelConfig,
}:

let

    majorMinor = with lib;
        let parts = versions.splitVersion baseKernel.version; in
        "${elemAt parts 0}.${elemAt parts 1}";

    patchForThisVersion =
        runCommand "cachyos-patch-${majorMinor}" {} ''
            patchName="0001-cachyos-base-all.patch"
            patchPath="${kernelPatches}/${majorMinor}/all/$patchName"
            cp "$patchPath" "$out"
        '';

    defconfig = "cachyos_defconfig";

    myConfig = import ./config.nix lib;

    # config raw from cachyos may interfere with structured config,
    # causing generate-config.pl to fail
    kconfigClearence = runCommand "kconfig-hack" {} ''
        cp "${kernelConfig}" config
        sed -i '/^#/d' config
        # remove meta config related to cc and ld
        sed -i '/^CONFIG_G*CC_/d' config
        sed -i '/^CONFIG_LD_/d' config
        sed -i '/^CONFIG_RUSTC*_/d' config
        sed -i '/^CONFIG_CC_/d' config
        sed -i '/^CONFIG_KUNIT$/d' config
        sed -i '/^CONFIG_RUNTIME_TESTING_MENU/d' config
        # remove drivers as they are defined in structured config
        sed -i '/^CONFIG_SND_/d' config
        # sed -i '/^CONFIG_NET_/d' config
        sed -i '/^CONFIG_.*_FS=/d' config
        sed -i '/^CONFIG_MMC_/d' config
        sed -i '/^CONFIG_MEMSTICK_/d' config
        sed -i '/^CONFIG_SYSTEM/d' config
        sed -i '/^CONFIG_MEDIA_/d' config
        sed -i '/^CONFIG_SSB/d' config
        sed -i '/^CONFIG_IIO/d' config
        sed -i '/^CONFIG_USB_/d' config
        # sed -i '/^CONFIG_PHY_/d' config
        # sed -i '/^CONFIG_DRM_/d' config
        # sed -i '/^CONFIG_FB_/d' config
        sed -i '/^CONFIG_MFD_/d' config
        sed -i '/^CONFIG_GPIO/d' config
        sed -i '/^CONFIG_REGULATOR/d' config
        sed -i '/^CONFIG_COMEDI/d' config
        # sed -i '/^CONFIG_SENSORS/d' config
        sed -i '/^CONFIG_BLK_DEV/d' config
        sed -i '/^CONFIG_SCSI_/d' config
        sed -i '/^CONFIG_DEBUG_/d' config
        sed -i '/^CONFIG_.*_PHY=/d' config
        sed -i '/^CONFIG_INPUT_/d' config
        sed -i '/^CONFIG_JOYSTICK_/d' config
        sed -i '/^CONFIG_PTP_1588_CLOCK/d' config
        sed -i '/^CONFIG_ATH/d' config
        # AI: merge multiple empty lines into one
        sed -i '/^$/N;/\n$/D' config
        cp config "$out"
    '';

    patchedSrc = stdenv.mkDerivation {
        pname = "linux-cachyos-${majorMinor}-src";
        inherit (baseKernel) version src;

        nativeBuildInputs = [ rsync perl ];
        dontConfigure = true;
        dontBuild = true;

        patches =
            let
                rmRandstruct = with lib;
                    filter (p: !hasInfix "randstruct" p);
            in
            (rmRandstruct baseKernel.patches)
            ++ [ patchForThisVersion ];

        postPatch = ''
            for dir in arch/*/configs; do
                install -Dm644 "${kconfigClearence}" "$dir/${defconfig}"
            done
        '';
        installPhase = ''
            mkdir -pv "$out"
            rsync -avhP "./" "$out/"
        '';
    };

    kernel = buildLinux {
        pname = "linux-cachyos";
        src = patchedSrc;
        version = lib.versions.pad 3 "${baseKernel.version}-cachyos";

        inherit defconfig;

        # deal with "error: unused option"
        # stupid nixpkgs default
        ignoreConfigErrors = true;

        structuredExtraConfig =
            myConfig
            // (with lib.kernel; {
                LOCALVERSION_AUTO = no;
                LOCALVERSION = freeform "-cachyos";
                LOGO = lib.mkForce yes;
                LOGO_LINUX_CLUT224 = yes;
            });

        extraPassthru = {
            packages = linuxKernel.packagesFor kernel;
            inherit kconfigClearence;
        };
    };

in kernel
