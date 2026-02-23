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
        rev = "505aef2086e584ba683a5ac1cb8ed8252fea2cfd";
        sha256 = "sha256-Ydg7qM+sdcpxxRSDpLCrK1B2iZkuAn84E0CQuRze3Oc=";
        postFetch = ''
            find "$out" -type f \
                ! -name "0001-cachyos-base-all.patch" \
                ! -path "*/sched/0001-bore-cachy.patch" -delete
            find "$out" -type d -empty -delete
        '';
    };

    kernelConfig = fetchFromGitHub {
        owner = "CachyOS";
        repo = "linux-cachyos";
        rev = "f086532ee69cb38cc6ff391f1d04ca0de4256e34";
        sha256 = "sha256-8OyN6x8QYIM1iddi/GGxG4C1OGYcUNSfuwThEXaWHHw=";
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
        version = "0-unstable-2026-02-19";
        src = kernelPatches;
        buildCommand = "ls $src > $out";
    };
    kernel-config-updater = stdenv.mkDerivation {
        pname = "cachyos-kernel-config";
        version = "6.17.9-unstable-2026-02-22";
        src = kernelConfig;
        buildCommand = "cat $src > $out";
    };

}
