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
        rev = "d2f1d070c0303b3b2bcb71df73c623a274258e22";
        sha256 = "sha256-IWz0FUhjO0n1KFaslmoDEexjnjGmuhYtU/fcEzf91o0=";
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
        rev = "e8675eeb9b48a23167b3e43f84e3be76e321935e";
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
        version = "0-unstable-2026-01-26";
        src = kernelPatches;
        buildCommand = "ls $src > $out";
    };
    kernel-config-updater = stdenv.mkDerivation {
        pname = "cachyos-kernel-config";
        version = "6.17.9-unstable-2026-01-26";
        src = kernelConfig;
        buildCommand = "cat $src > $out";
    };

}
