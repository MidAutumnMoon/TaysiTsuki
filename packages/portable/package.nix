# Based on pkgs.portableService but with own tweaks to fit my needs.
{
    lib,
    stdenv,
    erofs-utils,
    jq,
    closureInfo,
}:

{
    # The name and version of the portable service. The resulting image will be
    # created in result/$pname_$version.raw
    pname,
    version,

    # Units is a list of derivations for systemd unit files. Those files will be
    # copied to /etc/systemd/system in the resulting image. Note that the unit
    # names must be prefixed with the name of the portable service.
    units,

    # Basic info about the portable service image, used for the generated
    # /etc/os-release
    description ? null,

    # A list of attribute sets {object, symlink}. Symlinks will be created
    # in the root filesystem of the image to objects in the nix store.
    symlinks ? [ ],

    # A list of additional packages to be included in the image as-is.
    extraPackages ? [ ],

    # List of extra empty directories to create for the host to mount on.
    extraEmptyDirs ? [],

    # Extra commands to run after the image structure is set,
    # but before making the erofs image, allowing doing final tweaks.
    beforeCreateImage ? "",

    # erofs options
    erofsClusterSize ? 1 * 1024 * 1024,
}:

assert lib.strings.isValidPosixName pname;
assert lib.strings.isValidPosixName version;
assert lib.isString beforeCreateImage;

assert
    let c = lib.all (u: lib.hasPrefix pname u.name) units; in
    lib.assertMsg c "Units name must be prefixed with the service name";

assert
    let
        validSuffix = [ ".service" ".socket" ".target" ".timer" ".path" ];
        validUnit = u: with lib; any (s: hasSuffix s u.name) validSuffix;
        c = lib.all validUnit units;
    in
        lib.assertMsg c "Units name must have a valid suffix";

assert
    let c = with lib; all (d: hasPrefix "/" d) extraEmptyDirs; in
    lib.assertMsg c "Extra dirs must all be absolute paths";

let
    osRelease = ''
        IMAGE_ID="${pname}"
        IMAGE_VERSION="${version}"
        ${lib.optionalString
            (description != null)
            ''PORTABLE_PRETTY_NAME="${description}"''
        }
        PRETTY_NAME="NixOS"
        ID="nixos"
        BUILD_ID="rolling"
    '';
in

stdenv.mkDerivation (_drvSelf: {
    pname = "${pname}-img";
    inherit version;

    __structuredAttrs = true;

    nativeBuildInputs = [
        erofs-utils
        jq
    ];

    # make it overridable
    inherit osRelease;

    closureInfo = closureInfo {
        rootPaths =
            units
            ++ extraPackages
            ++ map (s: s.src) symlinks;
    };

    buildCommand = ''
        ROOT="root"
        mkdir -pv "$ROOT"
        mkdir -pv "$out" "$ROOT/nix/store"

        echo "Create scaffold"
        mkdir -pv \
            "$ROOT/etc/systemd/system" \
            "$ROOT"/{proc,sys,dev,run,tmp} \
            "$ROOT/var"/{tmp,cache,log}
        touch "$ROOT/etc/resolv.conf" "$ROOT/etc/machine-id"

        echo "Fill os-release"
        jq -r ".osRelease" "$NIX_ATTRS_JSON_FILE" > "$ROOT/etc/os-release"

        ${
            lib.flip map units (u: ''
                echo "Copy unit ${u.name}"
                cp -v "${u}" "$ROOT/etc/systemd/system/${u.name}"
            '' )
            |> lib.concatStringsSep "\n"
        }

        ${
            lib.flip map symlinks ({src, dst}: ''
                echo "Create symlink on ${dst}"
                mkdir -pv $(dirname "$ROOT/${dst}")
                ln -sfv "${src}" "$ROOT/${dst}"
            '' )
            |> lib.concatStringsSep "\n"
        }

        echo "Include extra store paths"
        for p in $(< "$closureInfo/store-paths")
        do
            # remove the leading "/" so that it becomes relative
            cp -av "$p" "$ROOT/''${p:1}"
        done

        echo "Create additional empty dirs"
        ${
            lib.flip map extraEmptyDirs (dir: ''
                mkdir -pv "$ROOT/${dir}"
            '' )
            |> lib.concatStringsSep "\n"
        }

        ${beforeCreateImage}

        echo "Create erofs image"
        mkfs.erofs "$out/${pname}_${version}.raw" "$ROOT" \
            -d5 -zlz4 \
            -Efragments,ztailpacking,dedupe \
            `# for reproducible build` \
            --ignore-mtime -Uclear -T0 \
            -C"${toString erofsClusterSize}"
    '';
})
