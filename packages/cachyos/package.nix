{
    callPackage,
    fetchFromGitHub,
    stdenv,

    linux_latest,
}:

rec {

    kernelVariant = "linux-cachyos";

    kernelPatches = fetchFromGitHub {
        owner = "CachyOS";
        repo = "kernel-patches";
        rev = "96d3efd823827b734074c0828c695d0c60d8a7d7";
        sha256 = "sha256-aGP+K93N5fNEnLpE9G3bcauPOu57de2DGB7aCL3zNm4=";
        postFetch = ''
            find "$out" -type f \
                ! -name "0001-cachyos-base-all.patch" \
                ! -path "*/sched/*" -delete
            find "$out" -type d -empty -delete
        '';
    };

    kernelConfig = fetchFromGitHub {
        owner = "CachyOS";
        repo = "linux-cachyos";
        rev = "3c3ffceb2ab21e7a67a0565ae636d1471893e35b";
        sha256 = "sha256-LgoguRNeGJjKQ5SSYF3ljk8CCudkSRbRyWGy0rFDGPk=";
        postFetch = ''
            hold="$(mktemp -d)"
            conf="$hold/conf"
            cp "$out/${kernelVariant}/config" "$conf"
            rm -rfv "$out"
            cp -v "$conf" "$out"
        '';
    };

    kernel = callPackage ./kernel.nix {
        inherit kernelPatches kernelConfig;
        baseKernel = linux_latest;
    };

    # TODO: implement subpackages in maintainance tool
    kernel-patches-updater = stdenv.mkDerivation {
        pname = "cachyos-kernel-patches";
        version = "0-unstable-2025-12-15";
        src = kernelPatches;
        buildCommand = "ls $src > $out";
    };
    kernel-config-updater = stdenv.mkDerivation {
        pname = "cachyos-kernel-config";
        version = "6.17.9-unstable-2025-12-15";
        src = kernelConfig;
        buildCommand = "cat $src > $out";
    };

}
