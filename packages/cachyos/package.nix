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
        rev = "cb320a13e3c92f32ada27acb1fba8a828a22ae60";
        sha256 = "sha256-479palXyP6zmfJRiEApiniU5Hv26X3ATUoocahweXUo=";
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
        rev = "5ece16c7b4a7d1261da68153cafc318a60b78ce8";
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
        version = "0-unstable-2026-02-16";
        src = kernelPatches;
        buildCommand = "ls $src > $out";
    };
    kernel-config-updater = stdenv.mkDerivation {
        pname = "cachyos-kernel-config";
        version = "6.17.9-unstable-2026-02-16";
        src = kernelConfig;
        buildCommand = "cat $src > $out";
    };

}
