# Based on:
# https://github.com/NixOS/nixpkgs/pull/161278

#
# Create a systemd portable service image
# https://systemd.io/PORTABLE_SERVICES/
#
# Example:
# makePortableServices {
#   pname = "demo";
#   version = "1.0";
#   units = [ demo-service demo-socket ];
# }
#

{
    lib,
    stdenvNoCC,

    closureInfo,
    writeText,
    squashfsTools,
}:

{
    # The name and version of the portable service.
    # The resulting image will be named as "$pname_$version.raw"
    name, # :: string
    version, # :: string

    # Units is a list of derivations for systemd unit files. Those files will be
    # copied to /etc/systemd/system in the resulting image. Note that the unit
    # names must be prefixed with the name of the portable service.
    units, # :: [ drv ]

    # Basic info about the portable service image, used for the generated
    # /etc/os-release
    description ? null, # :: string?
    homepage ? null, # :: string?

    # A list of attrsets of "{ src = <<drv>>; dst = "/path" }".
    # Symlinks will be created in the root fs of the image.
    symlinks ? [ ], # :: [ { src :: path; dst :: string } ]

    # A list of additional derivations to be included in the image as-is.
    contents ? [ ],

    # mksquashfs options
    squashfsCompressor ? "zstd",
    squashfsBlockSize ? "1M",
}:

let

    inherit ( lib )
        assertMsg
        concatStringsSep
    ;

    osRelease =
        {
            PORTABLE_ID = name;
            PORTABLE_PRETTY_NAME = description;
            HOME_URL = homepage;
            ID = "nixos";
            PRETTY_NAME = "NixOS";
            BUILD_ID = "rolling";
        }
        |> lib.filterAttrs ( _n: v: v != null )
        |> lib.generators.toKeyValue {}
        |> writeText "os-release"
    ;

    imgFootFs = stdenvNoCC.mkDerivation {
        pname = "root-fs-scaffold";
        inherit version;

        buildCommand = /* sh */ ''
            mkdir -pv "$out"

            # 1. The image contains /etc/os-release
            mkdir -pv "$out/etc"
            cp -v ${osRelease} $out/etc/os-release

            # 2. The image contains resolv.conf and machine-id
            mkdir -pv "$out/etc"
            touch "$out/etc/"{resolv.conf,machine-id}

            # 3. The image contains following directories
            mkdir -pv \
                "$out/proc" \
                "$out/sys" \
                "$out/dev" \
                "$out/run" \
                "$out/tmp" \
                "$out/var/tmp"

            # 4. Copy all units
            UNITS_DIR="$out/etc/systemd/system"
            mkdir -pv "$UNITS_DIR"
            ${
                units
                |> map ( it: ''cp -v ${it} "$UNITS_DIR/${it.name}"'' )
                |> concatStringsSep "\n"
            }
            unset UNITS_DIR

            # 5. Create symlinks
            ${
                symlinks
                |> map ( { src, dst }: ''
                    DST="$out/${dst}"
                    mkdir -pv "$( dirname "$DST" )"
                    ln -sv "${src}" "$DST"
                    unset DST
                '' )
                |> concatStringsSep "\n"
            }
        '';
    };

in

assert assertMsg
    ( name != "" && version != "" )
    "`name` and `version` can't be empty"
;

assert assertMsg
    ( lib.all ( u: lib.hasPrefix name u.name ) units )
    "Unit is required to have a prefix the same as the service name ${name}"
;

assert assertMsg
    ( lib.all ( attr: attr ? src && attr ? dst ) symlinks )
    "`symlinks` needed to be an attrsets of { src; dst }"
;

stdenvNoCC.mkDerivation {

    pname = "${name}-portable";
    version = version;

    nativeBuildInputs = [
        squashfsTools
    ];

    env.closureInfo = closureInfo {
        rootPaths = [ imgFootFs ] ++ contents;
    };

    buildCommand = /* bash */ ''
        mkdir -p "nix/store"

        for i in $( < "$closureInfo/store-paths" ); do
            cp -va "$i" "''${i:1}"
        done

        mkdir -p "$out"

        # the '.raw' suffix is mandatory by the portable service spec
        mksquashfs \
            nix ${imgFootFs}/* \
            $out/"${name}_${version}.raw" \
            -quiet -noappend -no-recovery \
            -exit-on-error \
            -keep-as-directory \
            -all-root -root-mode 755 \
            -b "${squashfsBlockSize}" -comp "${squashfsCompressor}"
    '';

}
