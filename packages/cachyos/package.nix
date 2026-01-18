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
        rev = "cba022ec33a81d60a1e2c9fe4622196e3fef2b54";
        sha256 = "sha256-m71+V0kDj73LlaABGMiL+w0NTImcoKCjJYTFc46z0JU=";
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
        rev = "4d7506c820f0d18fc0bbc36ecfec8ed126aee682";
        sha256 = "sha256-d1GhWEdENpt002r7mmVJ6n4FqJ/W+m8IZJl5ioWDwjo=";
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
        version = "0-unstable-2026-01-17";
        src = kernelPatches;
        buildCommand = "ls $src > $out";
    };
    kernel-config-updater = stdenv.mkDerivation {
        pname = "cachyos-kernel-config";
        version = "6.17.9-unstable-2026-01-17";
        src = kernelConfig;
        buildCommand = "cat $src > $out";
    };

}
