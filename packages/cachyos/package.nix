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
        rev = "6dfdbc7f8f3ee4d9f5dc8adfb0672ef5d8e1e3d5";
        sha256 = "sha256-TJJKd86jDyighG3Jx8MNyiuQTpEIMAsA2GkWpqttwFg=";
    };

    kernelConfig = fetchFromGitHub {
        owner = "CachyOS";
        repo = "linux-cachyos";
        rev = "5c8cf82f0ea40b72aec3fcbc58b449ca3b7cd372";
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
    nixUpdateTrick1 = stdenv.mkDerivation {
        pname = "cachyos-kernel-patches";
        version = "0-unstable-2025-12-08";
        src = kernelPatches;
        buildCommand = "ls $src > $out";
    };
    nixUpdateTrick2 = stdenv.mkDerivation {
        pname = "cachyos-kernel-config";
        version = "6.17.9-unstable-2025-12-09";
        src = kernelConfig;
        buildCommand = "cat $src > $out";
    };

}
