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
        rev = "b76feee309500d7ba6a955760ed4a8e698902ba3";
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
        version = "unstable";
        src = kernelPatches;
        buildCommand = "ls $src > $out";
    };
    nixUpdateTrick2 = stdenv.mkDerivation {
        pname = "cachyos-kernel-config";
        version = "unstable";
        src = kernelConfig;
        buildCommand = "cat $src > $out";
    };

}
